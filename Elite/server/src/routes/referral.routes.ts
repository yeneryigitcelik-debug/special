import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { query, getClient } from '../config/database.js';
import { authHook } from '../middleware/auth.js';
import type { ReferralCode } from '../types/index.js';

// Character set that avoids ambiguous chars (no 0, O, 1, I, L)
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 6;

function generateCode(): string {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)]!;
  }
  return code;
}

export default async function referralRoutes(app: FastifyInstance): Promise<void> {
  app.addHook('preHandler', authHook);

  // ── POST /referral/validate ─────────────────────────────────────
  app.post(
    '/referral/validate',
    async (
      request: FastifyRequest<{ Body: { code: string } }>,
      reply: FastifyReply
    ) => {
      const { code } = request.body as { code: string };

      if (!code || code.trim().length === 0) {
        return reply.code(400).send({ error: 'code is required' });
      }

      const result = await query<ReferralCode>(
        `SELECT * FROM referral_codes
         WHERE code = $1 AND is_used = FALSE AND expires_at > NOW()`,
        [code.toUpperCase().trim()]
      );

      if (result.rows.length === 0) {
        return reply.code(404).send({
          valid: false,
          error: 'Invalid, already used, or expired referral code',
        });
      }

      return reply.code(200).send({
        valid: true,
        referralCode: result.rows[0],
      });
    }
  );

  // ── POST /referral/redeem ───────────────────────────────────────
  app.post(
    '/referral/redeem',
    async (
      request: FastifyRequest<{ Body: { code: string } }>,
      reply: FastifyReply
    ) => {
      const { code } = request.body as { code: string };

      if (!code || code.trim().length === 0) {
        return reply.code(400).send({ error: 'code is required' });
      }

      const upperCode = code.toUpperCase().trim();
      const client = await getClient();

      try {
        await client.query('BEGIN');

        // Lock the referral code row for update
        const codeResult = await client.query<ReferralCode>(
          `SELECT * FROM referral_codes
           WHERE code = $1 AND is_used = FALSE AND expires_at > NOW()
           FOR UPDATE`,
          [upperCode]
        );

        if (codeResult.rows.length === 0) {
          await client.query('ROLLBACK');
          return reply.code(404).send({ error: 'Invalid, already used, or expired referral code' });
        }

        const referralCode = codeResult.rows[0]!;

        // Prevent self-referral
        if (referralCode.owner_id === request.userId) {
          await client.query('ROLLBACK');
          return reply.code(400).send({ error: 'Cannot redeem your own referral code' });
        }

        // Mark code as used
        await client.query(
          `UPDATE referral_codes
           SET is_used = TRUE, used_by = $1, used_at = NOW()
           WHERE id = $2`,
          [request.userId, referralCode.id]
        );

        // Activate the user's membership
        await client.query(
          `UPDATE profiles
           SET membership_status = 'active',
               referred_by = $1,
               waitlist_position = NULL,
               updated_at = NOW()
           WHERE id = $2`,
          [referralCode.owner_id, request.userId]
        );

        await client.query('COMMIT');

        return reply.code(200).send({
          message: 'Referral code redeemed. Membership activated.',
          membership_status: 'active',
        });
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      } finally {
        client.release();
      }
    }
  );

  // ── POST /referral/generate ─────────────────────────────────────
  app.post(
    '/referral/generate',
    async (request: FastifyRequest, reply: FastifyReply) => {
      // Only active members can generate referral codes
      const userResult = await query<{ membership_status: string }>(
        'SELECT membership_status FROM profiles WHERE id = $1',
        [request.userId]
      );

      if (
        userResult.rows.length === 0 ||
        userResult.rows[0]!.membership_status !== 'active'
      ) {
        return reply.code(403).send({ error: 'Only active members can generate referral codes' });
      }

      // Generate a unique code (retry if collision)
      let code: string;
      let attempts = 0;
      const maxAttempts = 10;

      do {
        code = generateCode();
        const existing = await query(
          'SELECT id FROM referral_codes WHERE code = $1',
          [code]
        );
        if (existing.rows.length === 0) break;
        attempts++;
      } while (attempts < maxAttempts);

      if (attempts >= maxAttempts) {
        return reply.code(500).send({ error: 'Failed to generate unique code. Try again.' });
      }

      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);

      const result = await query<ReferralCode>(
        `INSERT INTO referral_codes (owner_id, code, expires_at)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [request.userId, code, expiresAt.toISOString()]
      );

      return reply.code(201).send(result.rows[0]);
    }
  );
}
