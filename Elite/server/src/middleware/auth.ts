import type { FastifyRequest, FastifyReply } from 'fastify';
import { verifyAccessToken } from '../utils/jwt.js';

export async function authHook(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
  const authHeader = request.headers.authorization;

  if (!authHeader) {
    return reply.code(401).send({ error: 'Missing Authorization header' });
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return reply.code(401).send({ error: 'Invalid Authorization format. Use: Bearer <token>' });
  }

  const token = parts[1]!;

  try {
    const payload = verifyAccessToken(token);
    request.userId = payload.userId;
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Token verification failed';
    if (message.includes('expired')) {
      return reply.code(401).send({ error: 'Token expired' });
    }
    return reply.code(401).send({ error: 'Invalid token' });
  }
}
