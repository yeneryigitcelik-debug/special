import dotenv from 'dotenv';

dotenv.config();

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

function optionalEnv(key: string, fallback: string): string {
  return process.env[key] ?? fallback;
}

export const config = {
  NODE_ENV: optionalEnv('NODE_ENV', 'development'),
  PORT: parseInt(optionalEnv('PORT', '3000'), 10),

  // PostgreSQL
  DATABASE_URL: requireEnv('DATABASE_URL'),

  // Redis
  REDIS_URL: requireEnv('REDIS_URL'),

  // JWT
  JWT_SECRET: requireEnv('JWT_SECRET'),
  JWT_REFRESH_SECRET: requireEnv('JWT_REFRESH_SECRET'),

  // MinIO
  MINIO_ENDPOINT: requireEnv('MINIO_ENDPOINT'),
  MINIO_PORT: parseInt(optionalEnv('MINIO_PORT', '9000'), 10),
  MINIO_ACCESS_KEY: requireEnv('MINIO_ACCESS_KEY'),
  MINIO_SECRET_KEY: requireEnv('MINIO_SECRET_KEY'),
  MINIO_USE_SSL: optionalEnv('MINIO_USE_SSL', 'false') === 'true',

  // Apple Sign In
  APPLE_BUNDLE_ID: requireEnv('APPLE_BUNDLE_ID'),

  // API
  API_URL: requireEnv('API_URL'),
} as const;

export type Config = typeof config;
