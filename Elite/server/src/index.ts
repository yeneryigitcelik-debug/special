import Fastify from 'fastify';
import cors from '@fastify/cors';
import multipart from '@fastify/multipart';
import rateLimit from '@fastify/rate-limit';
import websocket from '@fastify/websocket';

import { config } from './config/env.js';
import { initBucket } from './config/minio.js';
import { setErrorHandler } from './middleware/errorHandler.js';

// Route modules
import authRoutes from './routes/auth.routes.js';
import profileRoutes from './routes/profile.routes.js';
import discoveryRoutes from './routes/discovery.routes.js';
import matchesRoutes from './routes/matches.routes.js';
import messagesRoutes from './routes/messages.routes.js';
import referralRoutes from './routes/referral.routes.js';
import photosRoutes from './routes/photos.routes.js';
import subscriptionRoutes from './routes/subscription.routes.js';

// WebSocket handler
import websocketHandler from './websocket/handler.js';

async function bootstrap(): Promise<void> {
  const app = Fastify({
    logger: {
      level: config.NODE_ENV === 'production' ? 'info' : 'debug',
      transport:
        config.NODE_ENV === 'development'
          ? { target: 'pino-pretty', options: { translateTime: 'HH:MM:ss Z', ignore: 'pid,hostname' } }
          : undefined,
    },
    trustProxy: true,
  });

  // ── Plugins ─────────────────────────────────────────────────────

  await app.register(cors, {
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  });

  await app.register(multipart, {
    limits: {
      fileSize: 10 * 1024 * 1024, // 10 MB
      files: 1,
    },
  });

  await app.register(rateLimit, {
    max: 100,
    timeWindow: '1 minute',
  });

  await app.register(websocket, {
    options: {
      maxPayload: 1024 * 64, // 64 KB
    },
  });

  // ── Error Handler ───────────────────────────────────────────────

  setErrorHandler(app);

  // ── Health Check ────────────────────────────────────────────────

  app.get('/api/v1/health', async (_request, reply) => {
    return reply.code(200).send({
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
    });
  });

  // ── API Routes (v1) ────────────────────────────────────────────

  await app.register(
    async (v1) => {
      await v1.register(authRoutes);
      await v1.register(profileRoutes);
      await v1.register(discoveryRoutes);
      await v1.register(matchesRoutes);
      await v1.register(messagesRoutes);
      await v1.register(referralRoutes);
      await v1.register(photosRoutes);
      await v1.register(subscriptionRoutes);
    },
    { prefix: '/api/v1' }
  );

  // ── WebSocket ───────────────────────────────────────────────────

  await app.register(websocketHandler);

  // ── Initialize Services ─────────────────────────────────────────

  try {
    await initBucket();
  } catch (err) {
    app.log.warn('MinIO bucket initialization failed (will retry on first upload): %s', err);
  }

  // ── Start Server ────────────────────────────────────────────────

  try {
    const address = await app.listen({
      port: config.PORT,
      host: '0.0.0.0',
    });
    app.log.info(`ELITE API running at ${address}`);
  } catch (err) {
    app.log.fatal(err);
    process.exit(1);
  }

  // ── Graceful Shutdown ───────────────────────────────────────────

  const signals: NodeJS.Signals[] = ['SIGINT', 'SIGTERM'];
  for (const signal of signals) {
    process.on(signal, async () => {
      app.log.info(`Received ${signal}, shutting down gracefully...`);
      await app.close();
      process.exit(0);
    });
  }
}

bootstrap();
