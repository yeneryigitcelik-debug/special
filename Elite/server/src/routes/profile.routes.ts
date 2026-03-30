import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { query } from '../config/database.js';
import { authHook } from '../middleware/auth.js';
import type { Profile } from '../types/index.js';

export default async function profileRoutes(app: FastifyInstance): Promise<void> {
  // All profile routes require authentication
  app.addHook('preHandler', authHook);

  // ── GET /profile ────────────────────────────────────────────────
  app.get(
    '/profile',
    async (request: FastifyRequest, reply: FastifyReply) => {
      const result = await query<Profile>(
        'SELECT * FROM profiles WHERE id = $1 AND is_active = TRUE',
        [request.userId]
      );

      if (result.rows.length === 0) {
        return reply.code(404).send({ error: 'Profile not found' });
      }

      return reply.code(200).send(result.rows[0]);
    }
  );

  // ── PUT /profile ────────────────────────────────────────────────
  app.put(
    '/profile',
    async (
      request: FastifyRequest<{
        Body: {
          display_name?: string;
          bio?: string;
          title?: string;
          location_city?: string;
          interest_tags?: string[];
          birthdate?: string;
          gender?: string;
          location_lat?: number;
          location_lon?: number;
        };
      }>,
      reply: FastifyReply
    ) => {
      const body = request.body as Record<string, unknown>;

      const allowedFields = [
        'display_name',
        'bio',
        'title',
        'location_city',
        'interest_tags',
        'birthdate',
        'gender',
        'location_lat',
        'location_lon',
      ];

      const updates: string[] = [];
      const values: unknown[] = [];
      let paramIndex = 1;

      for (const field of allowedFields) {
        if (body[field] !== undefined) {
          updates.push(`${field} = $${paramIndex}`);
          values.push(body[field]);
          paramIndex++;
        }
      }

      if (updates.length === 0) {
        return reply.code(400).send({ error: 'No valid fields to update' });
      }

      updates.push(`updated_at = NOW()`);
      values.push(request.userId);

      const sql = `
        UPDATE profiles
        SET ${updates.join(', ')}
        WHERE id = $${paramIndex} AND is_active = TRUE
        RETURNING *
      `;

      const result = await query<Profile>(sql, values);

      if (result.rows.length === 0) {
        return reply.code(404).send({ error: 'Profile not found' });
      }

      return reply.code(200).send(result.rows[0]);
    }
  );

  // ── GET /profiles/:id ───────────────────────────────────────────
  app.get(
    '/profiles/:id',
    async (
      request: FastifyRequest<{ Params: { id: string } }>,
      reply: FastifyReply
    ) => {
      const { id } = request.params;

      const result = await query(
        `SELECT id, display_name, birthdate, gender, bio, title,
                location_city, photo_urls, interest_tags, is_verified
         FROM profiles
         WHERE id = $1 AND is_active = TRUE AND membership_status = 'active'`,
        [id]
      );

      if (result.rows.length === 0) {
        return reply.code(404).send({ error: 'Profile not found' });
      }

      return reply.code(200).send(result.rows[0]);
    }
  );

  // ── PUT /profile/photos ─────────────────────────────────────────
  app.put(
    '/profile/photos',
    async (
      request: FastifyRequest<{
        Body: { photo_urls: string[] };
      }>,
      reply: FastifyReply
    ) => {
      const { photo_urls } = request.body as { photo_urls: string[] };

      if (!Array.isArray(photo_urls)) {
        return reply.code(400).send({ error: 'photo_urls must be an array' });
      }

      if (photo_urls.length > 6) {
        return reply.code(400).send({ error: 'Maximum 6 photos allowed' });
      }

      const result = await query<Profile>(
        `UPDATE profiles
         SET photo_urls = $1, updated_at = NOW()
         WHERE id = $2 AND is_active = TRUE
         RETURNING *`,
        [photo_urls, request.userId]
      );

      if (result.rows.length === 0) {
        return reply.code(404).send({ error: 'Profile not found' });
      }

      return reply.code(200).send(result.rows[0]);
    }
  );

  // ── DELETE /profile ─────────────────────────────────────────────
  app.delete(
    '/profile',
    async (request: FastifyRequest, reply: FastifyReply) => {
      const result = await query(
        `UPDATE profiles
         SET is_active = FALSE, updated_at = NOW()
         WHERE id = $1 AND is_active = TRUE
         RETURNING id`,
        [request.userId]
      );

      if (result.rows.length === 0) {
        return reply.code(404).send({ error: 'Profile not found' });
      }

      // Also delete refresh tokens so the user is effectively logged out
      await query('DELETE FROM refresh_tokens WHERE user_id = $1', [request.userId]);

      return reply.code(200).send({ message: 'Profile deactivated' });
    }
  );
}
