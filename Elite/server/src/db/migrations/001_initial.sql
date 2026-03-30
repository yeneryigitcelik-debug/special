-- ELITE Dating App - PostgreSQL Schema (standalone, no Supabase dependencies)
-- Migration 001: Initial schema

-- ── Profiles ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_id TEXT UNIQUE,
    display_name TEXT NOT NULL,
    birthdate DATE NOT NULL DEFAULT '2000-01-01',
    gender TEXT CHECK (gender IN ('male', 'female', 'non-binary', 'other')),
    bio TEXT,
    title TEXT,
    location_city TEXT,
    location_lat DOUBLE PRECISION,
    location_lon DOUBLE PRECISION,
    photo_urls TEXT[] DEFAULT '{}',
    interest_tags TEXT[] DEFAULT '{}',
    is_verified BOOLEAN DEFAULT FALSE,
    membership_status TEXT DEFAULT 'waitlist'
        CHECK (membership_status IN ('waitlist', 'active', 'suspended', 'banned')),
    subscription_tier TEXT DEFAULT 'free'
        CHECK (subscription_tier IN ('free', 'plus', 'black')),
    referred_by UUID REFERENCES profiles(id),
    waitlist_position INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Refresh Tokens ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Referral Codes ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS referral_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    used_by UUID REFERENCES profiles(id),
    used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Swipes ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS swipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swiper_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    swiped_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('like', 'pass', 'superlike')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(swiper_id, swiped_id)
);

-- ── Matches ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    matched_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);

-- ── Messages ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id),
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text'
        CHECK (message_type IN ('text', 'image', 'voice')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Daily Swipe Counts ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_swipe_counts (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    swipe_date DATE NOT NULL,
    count INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, swipe_date)
);

-- ── Indexes ─────────────────────────────────────────────────────────

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_apple_id ON profiles(apple_id);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(membership_status) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(last_active_at DESC)
    WHERE membership_status = 'active' AND is_active = TRUE;

-- Refresh tokens
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);

-- Referral codes
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(code) WHERE is_used = FALSE;
CREATE INDEX IF NOT EXISTS idx_referral_codes_owner ON referral_codes(owner_id);

-- Swipes
CREATE INDEX IF NOT EXISTS idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped ON swipes(swiped_id);

-- Matches
CREATE INDEX IF NOT EXISTS idx_matches_users ON matches(user1_id, user2_id);
CREATE INDEX IF NOT EXISTS idx_matches_user1 ON matches(user1_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_matches_user2 ON matches(user2_id) WHERE is_active = TRUE;

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_match ON messages(match_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(match_id, is_read) WHERE is_read = FALSE;

-- Daily swipe counts
CREATE INDEX IF NOT EXISTS idx_daily_swipe_counts_date ON daily_swipe_counts(swipe_date);
