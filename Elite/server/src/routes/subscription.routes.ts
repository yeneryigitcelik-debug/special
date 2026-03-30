import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { query } from '../config/database.js';
import { authHook } from '../middleware/auth.js';

// Map Apple product IDs to subscription tiers
const PRODUCT_TIER_MAP: Record<string, string> = {
  'com.elite.dating.plus.monthly': 'plus',
  'com.elite.dating.plus.yearly': 'plus',
  'com.elite.dating.black.monthly': 'black',
  'com.elite.dating.black.yearly': 'black',
};

export default async function subscriptionRoutes(app: FastifyInstance): Promise<void> {
  app.addHook('preHandler', authHook);

  // ── POST /subscription/verify ───────────────────────────────────
  app.post(
    '/subscription/verify',
    async (
      request: FastifyRequest<{
        Body: { productId: string; transactionId: string };
      }>,
      reply: FastifyReply
    ) => {
      const { productId, transactionId } = request.body as {
        productId: string;
        transactionId: string;
      };

      if (!productId || !transactionId) {
        return reply.code(400).send({ error: 'productId and transactionId are required' });
      }

      const tier = PRODUCT_TIER_MAP[productId];

      if (!tier) {
        return reply.code(400).send({
          error: 'Unknown product ID',
          validProducts: Object.keys(PRODUCT_TIER_MAP),
        });
      }

      // Update subscription tier in DB
      const result = await query(
        `UPDATE profiles
         SET subscription_tier = $1, updated_at = NOW()
         WHERE id = $2 AND is_active = TRUE
         RETURNING id, subscription_tier`,
        [tier, request.userId]
      );

      if (result.rows.length === 0) {
        return reply.code(404).send({ error: 'Profile not found' });
      }

      return reply.code(200).send({
        message: 'Subscription updated',
        subscription_tier: tier,
        transactionId,
      });
    }
  );
}
