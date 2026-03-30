// ── Core Domain Models ──────────────────────────────────────────────

export interface User {
  id: string;
  apple_id: string;
  display_name: string;
  membership_status: 'waitlist' | 'active' | 'suspended' | 'banned';
  subscription_tier: 'free' | 'plus' | 'black';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Profile {
  id: string;
  apple_id: string;
  display_name: string;
  birthdate: string;
  gender: 'male' | 'female' | 'non-binary' | 'other' | null;
  bio: string | null;
  title: string | null;
  location_city: string | null;
  location_lat: number | null;
  location_lon: number | null;
  photo_urls: string[];
  interest_tags: string[];
  is_verified: boolean;
  membership_status: 'waitlist' | 'active' | 'suspended' | 'banned';
  subscription_tier: 'free' | 'plus' | 'black';
  referred_by: string | null;
  waitlist_position: number | null;
  is_active: boolean;
  last_active_at: string;
  created_at: string;
  updated_at: string;
}

export interface Match {
  id: string;
  user1_id: string;
  user2_id: string;
  is_active: boolean;
  matched_at: string;
}

export interface MatchWithDetails {
  id: string;
  user1_id: string;
  user2_id: string;
  is_active: boolean;
  matched_at: string;
  otherProfile: {
    id: string;
    display_name: string;
    photo_urls: string[];
    bio: string | null;
    title: string | null;
  };
  lastMessage: {
    id: string;
    content: string;
    sender_id: string;
    message_type: string;
    is_read: boolean;
    created_at: string;
  } | null;
}

export interface Message {
  id: string;
  match_id: string;
  sender_id: string;
  content: string;
  message_type: 'text' | 'image' | 'voice';
  is_read: boolean;
  created_at: string;
}

export interface Swipe {
  id: string;
  swiper_id: string;
  swiped_id: string;
  action: 'like' | 'pass' | 'superlike';
  created_at: string;
}

export interface ReferralCode {
  id: string;
  owner_id: string;
  code: string;
  is_used: boolean;
  used_by: string | null;
  used_at: string | null;
  expires_at: string;
  created_at: string;
}

// ── Auth Types ──────────────────────────────────────────────────────

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

export interface JWTPayload {
  userId: string;
  iat: number;
  exp: number;
}

// ── WebSocket Types ─────────────────────────────────────────────────

export type WebSocketMessage =
  | { type: 'subscribe'; matchId: string }
  | { type: 'unsubscribe'; matchId: string }
  | { type: 'new_message'; message: Message }
  | { type: 'messages_read'; matchId: string; readBy: string }
  | { type: 'ping' }
  | { type: 'pong' }
  | { type: 'error'; message: string };

// ── Fastify Augmentation ────────────────────────────────────────────

declare module 'fastify' {
  interface FastifyRequest {
    userId: string;
  }
}
