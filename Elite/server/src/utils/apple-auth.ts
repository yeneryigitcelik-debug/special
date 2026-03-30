import appleSignin from 'apple-signin-auth';
import { config } from '../config/env.js';

interface AppleAuthResult {
  sub: string;
  email: string | undefined;
}

export async function verifyAppleToken(idToken: string): Promise<AppleAuthResult> {
  try {
    const payload = await appleSignin.verifyIdToken(idToken, {
      audience: config.APPLE_BUNDLE_ID,
      ignoreExpiration: false,
    });

    return {
      sub: payload.sub,
      email: payload.email,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    throw new Error(`Apple token verification failed: ${message}`);
  }
}
