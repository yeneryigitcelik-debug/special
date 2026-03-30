import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { query, getClient } from '../config/database.js';
import { verifyAppleToken } from '../utils/apple-auth.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../utils/jwt.js';
import { authHook } from '../middleware/auth.js';
import type { Profile, AuthResponse } from '../types/index.js';
import { v4 as uuidv4 } from 'uuid';

export default async function authRoutes(app: FastifyInstance): Promise<void> {
  // ── POST /auth/apple ────────────────────────────────────────────
  app.post(
    '/auth/apple',
    async (
      request: FastifyRequest<{
        Body: { idToken: string; displayName?: string };
      }>,
      reply: FastifyReply
    ) => {
      const { idToken, displayName } = request.body as {
        idToken: string;
        displayName?: string;
      };

      if (!idToken) {
        return reply.code(400).send({ error: 'idToken is required' });
      }

      // Verify the Apple identity token
      const appleUser = await verifyAppleToken(idToken);

      // Upsert user by apple_id
      const existingResult = await query<Profile>(
        'SELECT * FROM profiles WHERE apple_id = $1',
        [appleUser.sub]
      );

      let user: Profile;

      if (existingResult.rows.length > 0) {
        // Existing user -- update last_active_at
        const updateResult = await query<Profile>(
          `UPDATE profiles
           SET last_active_at = NOW(), updated_at = NOW()
           WHERE apple_id = $1
           RETURNING *`,
          [appleUser.sub]
        );
        user = updateResult.rows[0]!;
      } else {
        // New user -- insert
        const name = displayName || 'New Member';
        const insertResult = await query<Profile>(
          `INSERT INTO profiles (id, apple_id, display_name, birthdate, membership_status)
           VALUES ($1, $2, $3, '2000-01-01', 'waitlist')
           RETURNING *`,
          [uuidv4(), appleUser.sub, name]
        );
        user = insertResult.rows[0]!;
      }

      // Generate JWT pair
      const accessToken = signAccessToken(user.id);
      const refreshToken = signRefreshToken(user.id);

      // Persist refresh token in DB
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);

      await query(
        `INSERT INTO refresh_tokens (id, user_id, token, expires_at)
         VALUES ($1, $2, $3, $4)`,
        [uuidv4(), user.id, refreshToken, expiresAt.toISOString()]
      );

      const response: AuthResponse = {
        accessToken,
        refreshToken,
        user: {
          id: user.id,
          apple_id: user.apple_id,
          display_name: user.display_name,
          membership_status: user.membership_status,
          subscription_tier: user.subscription_tier,
          is_active: user.is_active,
          created_at: user.created_at,
          updated_at: user.updated_at,
        },
      };

      return reply.code(200).send(response);
    }
  );

  // ── POST /auth/refresh ──────────────────────────────────────────
  app.post(
    '/auth/refresh',
    async (
      request: FastifyRequest<{
        Body: { refreshToken: string };
      }>,
      reply: FastifyReply
    ) => {
      const { refreshToken } = request.body as { refreshToken: string };

      if (!refreshToken) {
        return reply.code(400).send({ error: 'refreshToken is required' });
      }

      // Verify the JWT signature
      let payload;
      try {
        payload = verifyRefreshToken(refreshToken);
      } catch {
        return reply.code(401).send({ error: 'Invalid or expired refresh token' });
      }

      // Check token exists in DB and is not expired
      const tokenResult = await query(
        `SELECT * FROM refresh_tokens
         WHERE token = $1 AND user_id = $2 AND expires_at > NOW()`,
        [refreshToken, payload.userId]
      );

      if (tokenResult.rows.length === 0) {
        return reply.code(401).send({ error: 'Refresh token revoked or expired' });
      }

      // Issue new access token
      const accessToken = signAccessToken(payload.userId);

      return reply.code(200).send({ accessToken });
    }
  );

  // ── POST /auth/logout ───────────────────────────────────────────
  app.post(
    '/auth/logout',
    { preHandler: [authHook] },
    async (request: FastifyRequest, reply: FastifyReply) => {
      const { refreshToken } = request.body as { refreshToken?: string };

      if (refreshToken) {
        // Delete specific refresh token
        await query(
          'DELETE FROM refresh_tokens WHERE token = $1 AND user_id = $2',
          [refreshToken, request.userId]
        );
      } else {
        // Delete all refresh tokens for the user
        await query(
          'DELETE FROM refresh_tokens WHERE user_id = $1',
          [request.userId]
        );
      }

      return reply.code(200).send({ message: 'Logged out' });
    }
  );
}
