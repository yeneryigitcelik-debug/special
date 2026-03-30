import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { query } from '../config/database.js';
import { authHook } from '../middleware/auth.js';

const FREE_TIER_DAILY_LIMIT = 50;

export default async function discoveryRoutes(app: FastifyInstance): Promise<void> {
  app.addHook('preHandler', authHook);

  // ── GET /discovery/profiles ─────────────────────────────────────
  app.get(
    '/discovery/profiles',
    async (
      request: FastifyRequest<{
        Querystring: { limit?: string; offset?: string };
      }>,
      reply: FastifyReply
    ) => {
      const qs = request.query as { limit?: string; offset?: string };
      const limit = Math.min(parseInt(qs.limit || '20', 10), 50);
      const offset = parseInt(qs.offset || '0', 10);

      // Get current user's subscription tier
      const userResult = await query<{ subscription_tier: string }>(
        'SELECT subscription_tier FROM profiles WHERE id = $1',
        [request.userId]
      );

      if (userResult.rows.length === 0) {
        return reply.code(404).send({ error: 'Profile not found' });
      }

      const tier = userResult.rows[0]!.subscription_tier;

      // For free tier, enforce daily swipe limit
      if (tier === 'free') {
        const today = new Date().toISOString().split('T')[0]!;

        const countResult = await query<{ count: number }>(
          `SELECT count FROM daily_swipe_counts
           WHERE user_id = $1 AND swipe_date = $2`,
          [request.userId, today]
        );

        const usedToday = countResult.rows[0]?.count ?? 0;

        if (usedToday >= FREE_TIER_DAILY_LIMIT) {
          return reply.code(200).send({
            profiles: [],
            remaining_swipes: 0,
            message: 'Daily swipe limit reached. Upgrade to Plus or Black for unlimited swipes.',
          });
        }

        // Cap the number of profiles returned to remaining swipes
        const remaining = FREE_TIER_DAILY_LIMIT - usedToday;
        const effectiveLimit = Math.min(limit, remaining);

        const profiles = await query(
          `SELECT p.id, p.display_name, p.birthdate, p.gender, p.bio, p.title,
                  p.location_city, p.photo_urls, p.interest_tags, p.is_verified,
                  p.last_active_at
           FROM profiles p
           WHERE p.is_active = TRUE
             AND p.membership_status = 'active'
             AND p.id != $1
             AND p.id NOT IN (
               SELECT swiped_id FROM swipes WHERE swiper_id = $1
             )
           ORDER BY p.last_active_at DESC
           LIMIT $2 OFFSET $3`,
          [request.userId, effectiveLimit, offset]
        );

        return reply.code(200).send({
          profiles: profiles.rows,
          remaining_swipes: remaining,
        });
      }

      // Plus / Black -- unlimited swipes
      const profiles = await query(
        `SELECT p.id, p.display_name, p.birthdate, p.gender, p.bio, p.title,
                p.location_city, p.photo_urls, p.interest_tags, p.is_verified,
                p.last_active_at
         FROM profiles p
         WHERE p.is_active = TRUE
           AND p.membership_status = 'active'
           AND p.id != $1
           AND p.id NOT IN (
             SELECT swiped_id FROM swipes WHERE swiper_id = $1
           )
         ORDER BY p.last_active_at DESC
         LIMIT $2 OFFSET $3`,
        [request.userId, limit, offset]
      );

      return reply.code(200).send({
        profiles: profiles.rows,
        remaining_swipes: -1, // unlimited
      });
    }
  );
}
