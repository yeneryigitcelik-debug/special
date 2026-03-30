import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { query } from '../config/database.js';
import { redis } from '../config/redis.js';
import { authHook } from '../middleware/auth.js';
import type { Message } from '../types/index.js';
import { v4 as uuidv4 } from 'uuid';

export default async function messagesRoutes(app: FastifyInstance): Promise<void> {
  app.addHook('preHandler', authHook);

  // ── GET /matches/:matchId/messages ──────────────────────────────
  app.get(
    '/matches/:matchId/messages',
    async (
      request: FastifyRequest<{
        Params: { matchId: string };
        Querystring: { limit?: string; before?: string };
      }>,
      reply: FastifyReply
    ) => {
      const { matchId } = request.params;
      const qs = request.query as { limit?: string; before?: string };
      const limit = Math.min(parseInt(qs.limit || '50', 10), 100);

      // Verify the user belongs to this match
      const matchResult = await query(
        `SELECT id FROM matches
         WHERE id = $1 AND (user1_id = $2 OR user2_id = $2) AND is_active = TRUE`,
        [matchId, request.userId]
      );

      if (matchResult.rows.length === 0) {
        return reply.code(403).send({ error: 'Not a member of this match' });
      }

      // Paginate messages (cursor-based using "before" timestamp)
      let sql: string;
      let params: unknown[];

      if (qs.before) {
        sql = `
          SELECT * FROM messages
          WHERE match_id = $1 AND created_at < $2
          ORDER BY created_at DESC
          LIMIT $3
        `;
        params = [matchId, qs.before, limit];
      } else {
        sql = `
          SELECT * FROM messages
          WHERE match_id = $1
          ORDER BY created_at DESC
          LIMIT $2
        `;
        params = [matchId, limit];
      }

      const result = await query<Message>(sql, params);

      return reply.code(200).send(result.rows);
    }
  );

  // ── POST /matches/:matchId/messages ─────────────────────────────
  app.post(
    '/matches/:matchId/messages',
    async (
      request: FastifyRequest<{
        Params: { matchId: string };
        Body: { content: string; message_type?: 'text' | 'image' | 'voice' };
      }>,
      reply: FastifyReply
    ) => {
      const { matchId } = request.params;
      const body = request.body as {
        content: string;
        message_type?: 'text' | 'image' | 'voice';
      };

      if (!body.content || body.content.trim().length === 0) {
        return reply.code(400).send({ error: 'Message content is required' });
      }

      const messageType = body.message_type || 'text';

      if (!['text', 'image', 'voice'].includes(messageType)) {
        return reply.code(400).send({ error: 'Invalid message_type' });
      }

      // Verify user belongs to this match
      const matchResult = await query(
        `SELECT id FROM matches
         WHERE id = $1 AND (user1_id = $2 OR user2_id = $2) AND is_active = TRUE`,
        [matchId, request.userId]
      );

      if (matchResult.rows.length === 0) {
        return reply.code(403).send({ error: 'Not a member of this match' });
      }

      // Insert message
      const result = await query<Message>(
        `INSERT INTO messages (id, match_id, sender_id, content, message_type)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [uuidv4(), matchId, request.userId, body.content.trim(), messageType]
      );

      const message = result.rows[0]!;

      // Publish to Redis for real-time delivery via WebSocket
      await redis.publish(
        `match:${matchId}`,
        JSON.stringify({ type: 'new_message', message })
      );

      return reply.code(201).send(message);
    }
  );

  // ── PUT /matches/:matchId/messages/read ─────────────────────────
  app.put(
    '/matches/:matchId/messages/read',
    async (
      request: FastifyRequest<{ Params: { matchId: string } }>,
      reply: FastifyReply
    ) => {
      const { matchId } = request.params;

      // Verify user belongs to this match
      const matchResult = await query(
        `SELECT id FROM matches
         WHERE id = $1 AND (user1_id = $2 OR user2_id = $2) AND is_active = TRUE`,
        [matchId, request.userId]
      );

      if (matchResult.rows.length === 0) {
        return reply.code(403).send({ error: 'Not a member of this match' });
      }

      // Mark all unread messages (sent by the other user) as read
      const result = await query(
        `UPDATE messages
         SET is_read = TRUE
         WHERE match_id = $1 AND sender_id != $2 AND is_read = FALSE
         RETURNING id`,
        [matchId, request.userId]
      );

      // Notify via Redis
      if (result.rowCount && result.rowCount > 0) {
        await redis.publish(
          `match:${matchId}`,
          JSON.stringify({
            type: 'messages_read',
            matchId,
            readBy: request.userId,
          })
        );
      }

      return reply.code(200).send({
        updated: result.rowCount ?? 0,
      });
    }
  );
}
