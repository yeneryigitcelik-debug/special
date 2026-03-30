import { Redis } from 'ioredis';
import { config } from './env.js';

export const redis = new Redis(config.REDIS_URL, {
  maxRetriesPerRequest: 3,
  retryStrategy(times: number) {
    const delay = Math.min(times * 200, 5000);
    return delay;
  },
  lazyConnect: false,
});

redis.on('connect', () => {
  console.log('[Redis] Connected (main)');
});

redis.on('error', (err: Error) => {
  console.error('[Redis] Main connection error:', err.message);
});

// Separate connection dedicated to pub/sub (subscriber connections
// cannot issue regular commands once subscribed)
export const redisSub = new Redis(config.REDIS_URL, {
  maxRetriesPerRequest: 3,
  retryStrategy(times: number) {
    const delay = Math.min(times * 200, 5000);
    return delay;
  },
  lazyConnect: false,
});

redisSub.on('connect', () => {
  console.log('[Redis] Connected (pub/sub subscriber)');
});

redisSub.on('error', (err: Error) => {
  console.error('[Redis] Subscriber connection error:', err.message);
});
