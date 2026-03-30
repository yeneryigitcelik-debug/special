import jwt from 'jsonwebtoken';
import { config } from '../config/env.js';
import type { JWTPayload } from '../types/index.js';

const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '30d';

export function signAccessToken(userId: string): string {
  return jwt.sign({ userId } satisfies Pick<JWTPayload, 'userId'>, config.JWT_SECRET, {
    expiresIn: ACCESS_TOKEN_EXPIRY,
  });
}

export function signRefreshToken(userId: string): string {
  return jwt.sign({ userId } satisfies Pick<JWTPayload, 'userId'>, config.JWT_REFRESH_SECRET, {
    expiresIn: REFRESH_TOKEN_EXPIRY,
  });
}

export function verifyAccessToken(token: string): JWTPayload {
  return jwt.verify(token, config.JWT_SECRET) as JWTPayload;
}

export function verifyRefreshToken(token: string): JWTPayload {
  return jwt.verify(token, config.JWT_REFRESH_SECRET) as JWTPayload;
}
