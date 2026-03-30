import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { authHook } from '../middleware/auth.js';
import { minioClient, BUCKET_NAME } from '../config/minio.js';
import { config } from '../config/env.js';
import sharp from 'sharp';
import { v4 as uuidv4 } from 'uuid';

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
const MAX_DIMENSION = 1200;
const ALLOWED_MIMETYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

export default async function photosRoutes(app: FastifyInstance): Promise<void> {
  app.addHook('preHandler', authHook);

  // ── POST /photos/upload ─────────────────────────────────────────
  app.post(
    '/photos/upload',
    async (request: FastifyRequest, reply: FastifyReply) => {
      const file = await request.file();

      if (!file) {
        return reply.code(400).send({ error: 'No file uploaded' });
      }

      if (!ALLOWED_MIMETYPES.includes(file.mimetype)) {
        return reply.code(400).send({
          error: `Invalid file type. Allowed: ${ALLOWED_MIMETYPES.join(', ')}`,
        });
      }

      // Read file into buffer
      const chunks: Buffer[] = [];
      let totalSize = 0;

      for await (const chunk of file.file) {
        totalSize += chunk.length;
        if (totalSize > MAX_FILE_SIZE) {
          return reply.code(413).send({ error: 'File too large. Maximum 10 MB.' });
        }
        chunks.push(chunk);
      }

      // Check if the stream was truncated by multipart limits
      if (file.file.truncated) {
        return reply.code(413).send({ error: 'File too large. Maximum 10 MB.' });
      }

      const rawBuffer = Buffer.concat(chunks);

      // Resize with sharp (max 1200px on longest side), convert to JPEG
      const processedBuffer = await sharp(rawBuffer)
        .resize(MAX_DIMENSION, MAX_DIMENSION, {
          fit: 'inside',
          withoutEnlargement: true,
        })
        .jpeg({ quality: 85, progressive: true })
        .toBuffer();

      const filename = `${uuidv4()}.jpg`;
      const objectName = `${request.userId}/${filename}`;

      // Upload to MinIO
      await minioClient.putObject(BUCKET_NAME, objectName, processedBuffer, processedBuffer.length, {
        'Content-Type': 'image/jpeg',
      });

      // Build the public URL
      const protocol = config.MINIO_USE_SSL ? 'https' : 'http';
      const url = `${protocol}://${config.MINIO_ENDPOINT}:${config.MINIO_PORT}/${BUCKET_NAME}/${objectName}`;

      return reply.code(201).send({ url, filename });
    }
  );

  // ── DELETE /photos/:filename ────────────────────────────────────
  app.delete(
    '/photos/:filename',
    async (
      request: FastifyRequest<{ Params: { filename: string } }>,
      reply: FastifyReply
    ) => {
      const { filename } = request.params;

      if (!filename) {
        return reply.code(400).send({ error: 'filename is required' });
      }

      const objectName = `${request.userId}/${filename}`;

      try {
        // Verify object exists before deleting
        await minioClient.statObject(BUCKET_NAME, objectName);
      } catch {
        return reply.code(404).send({ error: 'Photo not found' });
      }

      await minioClient.removeObject(BUCKET_NAME, objectName);

      return reply.code(200).send({ message: 'Photo deleted' });
    }
  );
}
