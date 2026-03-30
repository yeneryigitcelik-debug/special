import type { FastifyInstance } from 'fastify';
import type { WebSocket } from '@fastify/websocket';
import { verifyAccessToken } from '../utils/jwt.js';
import { query } from '../config/database.js';
import { redisSub } from '../config/redis.js';
import type { WebSocketMessage } from '../types/index.js';

// Track connected clients per match room
// matchId -> Set of { ws, userId }
interface ConnectedClient {
  ws: WebSocket;
  userId: string;
}

const rooms = new Map<string, Set<ConnectedClient>>();

// Track which match channels we have active Redis subscriptions for
const subscribedChannels = new Set<string>();

function broadcastToRoom(matchId: string, message: string, excludeUserId?: string): void {
  const room = rooms.get(matchId);
  if (!room) return;

  for (const client of room) {
    if (excludeUserId && client.userId === excludeUserId) continue;
    if (client.ws.readyState === 1) {
      // WebSocket.OPEN
      client.ws.send(message);
    }
  }
}

function addToRoom(matchId: string, client: ConnectedClient): void {
  let room = rooms.get(matchId);
  if (!room) {
    room = new Set();
    rooms.set(matchId, room);
  }
  room.add(client);
}

function removeFromRoom(matchId: string, client: ConnectedClient): void {
  const room = rooms.get(matchId);
  if (!room) return;
  room.delete(client);
  if (room.size === 0) {
    rooms.delete(matchId);
  }
}

function removeFromAllRooms(client: ConnectedClient): void {
  for (const [matchId, room] of rooms) {
    room.delete(client);
    if (room.size === 0) {
      rooms.delete(matchId);
    }
  }
}

// Initialize Redis pub/sub message handler (called once)
let redisListenerInitialized = false;

function initRedisListener(): void {
  if (redisListenerInitialized) return;
  redisListenerInitialized = true;

  redisSub.on('message', (channel: string, message: string) => {
    // channel format: "match:{matchId}"
    const matchId = channel.replace('match:', '');
    broadcastToRoom(matchId, message);
  });
}

async function subscribeToChannel(matchId: string): Promise<void> {
  const channel = `match:${matchId}`;
  if (subscribedChannels.has(channel)) return;
  subscribedChannels.add(channel);
  await redisSub.subscribe(channel);
}

export default async function websocketHandler(app: FastifyInstance): Promise<void> {
  initRedisListener();

  app.get(
    '/ws',
    { websocket: true },
    async (socket: WebSocket, request) => {
      // ── Authenticate via query parameter ──────────────────────
      const url = new URL(request.url, 'http://localhost');
      const token = url.searchParams.get('token');

      if (!token) {
        socket.send(
          JSON.stringify({ type: 'error', message: 'Missing token query parameter' } satisfies WebSocketMessage)
        );
        socket.close(4001, 'Unauthorized');
        return;
      }

      let userId: string;
      try {
        const payload = verifyAccessToken(token);
        userId = payload.userId;
      } catch {
        socket.send(
          JSON.stringify({ type: 'error', message: 'Invalid or expired token' } satisfies WebSocketMessage)
        );
        socket.close(4001, 'Unauthorized');
        return;
      }

      const client: ConnectedClient = { ws: socket, userId };

      // ── Ping/pong keepalive ───────────────────────────────────
      const pingInterval = setInterval(() => {
        if (socket.readyState === 1) {
          socket.send(JSON.stringify({ type: 'ping' } satisfies WebSocketMessage));
        }
      }, 30000);

      // ── Handle incoming messages ──────────────────────────────
      socket.on('message', async (raw: Buffer | ArrayBuffer | Buffer[]) => {
        let data: WebSocketMessage;
        try {
          const text = typeof raw === 'string' ? raw : raw.toString();
          data = JSON.parse(text) as WebSocketMessage;
        } catch {
          socket.send(
            JSON.stringify({ type: 'error', message: 'Invalid JSON' } satisfies WebSocketMessage)
          );
          return;
        }

        switch (data.type) {
          case 'subscribe': {
            // Verify user is a member of this match before subscribing
            const matchResult = await query(
              `SELECT id FROM matches
               WHERE id = $1 AND (user1_id = $2 OR user2_id = $2) AND is_active = TRUE`,
              [data.matchId, userId]
            );

            if (matchResult.rows.length === 0) {
              socket.send(
                JSON.stringify({
                  type: 'error',
                  message: 'Not a member of this match',
                } satisfies WebSocketMessage)
              );
              return;
            }

            addToRoom(data.matchId, client);
            await subscribeToChannel(data.matchId);
            break;
          }

          case 'unsubscribe': {
            removeFromRoom(data.matchId, client);
            break;
          }

          case 'pong': {
            // Client responded to our ping -- connection is alive
            break;
          }

          default: {
            socket.send(
              JSON.stringify({
                type: 'error',
                message: 'Unknown message type',
              } satisfies WebSocketMessage)
            );
          }
        }
      });

      // ── Cleanup on disconnect ─────────────────────────────────
      socket.on('close', () => {
        clearInterval(pingInterval);
        removeFromAllRooms(client);
      });

      socket.on('error', () => {
        clearInterval(pingInterval);
        removeFromAllRooms(client);
      });
    }
  );
}
