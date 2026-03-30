-- ÉLITE Dating App — Supabase Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    birthdate DATE NOT NULL,
    gender TEXT CHECK (gender IN ('male', 'female', 'non-binary', 'other')),
    bio TEXT,
    title TEXT,
    location_city TEXT,
    location_lat DOUBLE PRECISION,
    location_lon DOUBLE PRECISION,
    photo_urls TEXT[] DEFAULT '{}',
    interest_tags TEXT[] DEFAULT '{}',
    is_verified BOOLEAN DEFAULT FALSE,
    membership_status TEXT DEFAULT 'waitlist' CHECK (membership_status IN ('waitlist', 'active', 'suspended', 'banned')),
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'plus', 'black')),
    referred_by UUID REFERENCES profiles(id),
    waitlist_position INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Referral codes table
CREATE TABLE referral_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    used_by UUID REFERENCES profiles(id),
    used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Swipes table
CREATE TABLE swipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swiper_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    swiped_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('like', 'pass', 'superlike')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(swiper_id, swiped_id)
);

-- Matches table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    matched_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id),
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'voice')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Profiles are viewable by active members" ON profiles
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        (SELECT membership_status FROM profiles WHERE id = auth.uid()) = 'active'
    );

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own referral codes" ON referral_codes
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Anyone can validate a referral code" ON referral_codes
    FOR SELECT USING (is_used = FALSE);

CREATE POLICY "Users can insert referral codes" ON referral_codes
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own referral codes" ON referral_codes
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own swipes" ON swipes
    FOR INSERT WITH CHECK (auth.uid() = swiper_id);

CREATE POLICY "Users can view own swipes" ON swipes
    FOR SELECT USING (auth.uid() = swiper_id);

CREATE POLICY "Users can view own matches" ON matches
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "System can create matches" ON matches
    FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can send messages in their matches" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        match_id IN (
            SELECT id FROM matches
            WHERE (user1_id = auth.uid() OR user2_id = auth.uid()) AND is_active = TRUE
        )
    );

CREATE POLICY "Users can read messages in their matches" ON messages
    FOR SELECT USING (
        match_id IN (
            SELECT id FROM matches
            WHERE (user1_id = auth.uid() OR user2_id = auth.uid()) AND is_active = TRUE
        )
    );

CREATE POLICY "Users can update message read status" ON messages
    FOR UPDATE USING (
        match_id IN (
            SELECT id FROM matches
            WHERE (user1_id = auth.uid() OR user2_id = auth.uid()) AND is_active = TRUE
        )
    );

-- Performance indexes
CREATE INDEX idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX idx_swipes_swiped ON swipes(swiped_id);
CREATE INDEX idx_matches_users ON matches(user1_id, user2_id);
CREATE INDEX idx_messages_match ON messages(match_id, created_at DESC);
CREATE INDEX idx_profiles_status ON profiles(membership_status) WHERE is_active = TRUE;
CREATE INDEX idx_referral_codes_code ON referral_codes(code) WHERE is_used = FALSE;
CREATE INDEX idx_profiles_active ON profiles(last_active_at DESC) WHERE membership_status = 'active' AND is_active = TRUE;

-- Storage bucket for profile photos
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', true);

-- Storage policies
CREATE POLICY "Users can upload own photos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'profile-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-photos');

CREATE POLICY "Users can delete own photos" ON storage.objects
    FOR DELETE USING (bucket_id = 'profile-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Enable Realtime for messages
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
