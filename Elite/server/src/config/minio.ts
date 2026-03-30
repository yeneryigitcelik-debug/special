import * as Minio from 'minio';
import { config } from './env.js';

export const minioClient = new Minio.Client({
  endPoint: config.MINIO_ENDPOINT,
  port: config.MINIO_PORT,
  useSSL: config.MINIO_USE_SSL,
  accessKey: config.MINIO_ACCESS_KEY,
  secretKey: config.MINIO_SECRET_KEY,
});

const BUCKET_NAME = 'profile-photos';

const publicReadPolicy = {
  Version: '2012-10-17',
  Statement: [
    {
      Effect: 'Allow',
      Principal: { AWS: ['*'] },
      Action: ['s3:GetObject'],
      Resource: [`arn:aws:s3:::${BUCKET_NAME}/*`],
    },
  ],
};

export async function initBucket(): Promise<void> {
  try {
    const exists = await minioClient.bucketExists(BUCKET_NAME);
    if (!exists) {
      await minioClient.makeBucket(BUCKET_NAME);
      console.log(`[MinIO] Bucket "${BUCKET_NAME}" created`);
    }

    await minioClient.setBucketPolicy(
      BUCKET_NAME,
      JSON.stringify(publicReadPolicy)
    );
    console.log(`[MinIO] Public read policy set on "${BUCKET_NAME}"`);
  } catch (err) {
    console.error('[MinIO] Error initializing bucket:', err);
    throw err;
  }
}

export { BUCKET_NAME };
