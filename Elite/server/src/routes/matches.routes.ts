import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { query, getClient } from '../config/database.js';
import { authHook } from '../middleware/auth.js';
import type { Swipe, Match, MatchWithDetails } from '../types/index.js';

export default async function matchesRoutes(app: FastifyInstance): Promise<void> {
  app.addHook('preHandler', authHook);

  // ── POST /swipes ────────────────────────────────────────────────
  app.post(
    '/swipes',
    async (
      request: FastifyRequest<{
        Body: { swiped_id: string; action: 'like' | 'pass' | 'superlike' };
      }>,
      reply: FastifyReply
    ) => {
      const { swiped_id, action } = request.body as {
        swiped_id: string;
        action: 'like' | 'pass' | 'superlike';
      };

      if (!swiped_id || !action) {
        return reply.code(400).send({ error: 'swiped_id and action are required' });
      }

      if (!['like', 'pass', 'superlike'].includes(action)) {
        return reply.code(400).send({ error: 'action must be like, pass, or superlike' });
      }

      if (swiped_id === request.userId) {
        return reply.code(400).send({ error: 'Cannot swipe on yourself' });
      }

      const client = await getClient();

      try {
        await client.query('BEGIN');

        // Record the swipe
        const swipeResult = await client.query<Swipe>(
          `INSERT INTO swipes (swiper_id, swiped_id, action)
           VALUES ($1, $2, $3)
           ON CONFLICT (swiper_id, swiped_id) DO UPDATE SET action = $3, created_at = NOW()
           RETURNING *`,
          [request.userId, swiped_id, action]
        );

        // Increment daily swipe count
        const today = new Date().toISOString().split('T')[0]!;
        await client.query(
          `INSERT INTO daily_swipe_counts (user_id, swipe_date, count)
           VALUES ($1, $2, 1)
           ON CONFLICT (user_id, swipe_date)
           DO UPDATE SET count = daily_swipe_counts.count + 1`,
          [request.userId, today]
        );

        let match: Match | null = null;

        // Check for mutual like/superlike
        if (action === 'like' || action === 'superlike') {
          const mutualResult = await client.query(
            `SELECT id FROM swipes
             WHERE swiper_id = $1 AND swiped_id = $2 AND action IN ('like', 'superlike')`,
            [swiped_id, request.userId]
          );

          if (mutualResult.rows.length > 0) {
            // Ensure consistent ordering: smaller UUID is user1_id
            const [user1, user2] =
              request.userId < swiped_id
                ? [request.userId, swiped_id]
                : [swiped_id, request.userId];

            const matchResult = await client.query<Match>(
              `INSERT INTO matches (user1_id, user2_id)
               VALUES ($1, $2)
               ON CONFLICT (user1_id, user2_id) DO NOTHING
               RETURNING *`,
              [user1, user2]
            );

            if (matchResult.rows.length > 0) {
              match = matchResult.rows[0]!;
            }
          }
        }

        await client.query('COMMIT');

        return reply.code(201).send({
          swipe: swipeResult.rows[0],
          match,
        });
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      } finally {
        client.release();
      }
    }
  );

  // ── GET /matches ────────────────────────────────────────────────
  app.get(
    '/matches',
    async (request: FastifyRequest, reply: FastifyReply) => {
      const result = await query<MatchWithDetails>(
        `SELECT
           m.id,
           m.user1_id,
           m.user2_id,
           m.is_active,
           m.matched_at,
           json_build_object(
             'id', other.id,
             'display_name', other.display_name,
             'photo_urls', other.photo_urls,
             'bio', other.bio,
             'title', other.title
           ) AS "otherProfile",
           (
             SELECT json_build_object(
               'id', msg.id,
               'content', msg.content,
               'sender_id', msg.sender_id,
               'message_type', msg.message_type,
               'is_read', msg.is_read,
               'created_at', msg.created_at
             )
             FROM messages msg
             WHERE msg.match_id = m.id
             ORDER BY msg.created_at DESC
             LIMIT 1
           ) AS "lastMessage"
         FROM matches m
         JOIN profiles other ON other.id = CASE
           WHEN m.user1_id = $1 THEN m.user2_id
           ELSE m.user1_id
         END
         WHERE (m.user1_id = $1 OR m.user2_id = $1)
           AND m.is_active = TRUE
           AND other.is_active = TRUE
         ORDER BY m.matched_at DESC`,
        [request.userId]
      );

      return reply.code(200).send(result.rows);
    }
  );
}
