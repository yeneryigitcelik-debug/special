# ÉLITE

**Invite-Only Premium Dating App**

> Exclusivity breeds quality. Every interaction should feel intentional, refined, and elevated.

ÉLITE is an ultra-premium, invite-only dating app inspired by RAYA. Only available on iOS (App Store). Users can only join through a referral code from an existing member or by being accepted from a waitlist after committee review.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Platform** | iOS only (iPhone) |
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI |
| **Minimum iOS** | 17.0 |
| **Architecture** | MVVM + Clean Architecture |
| **Backend** | Supabase (Auth, Database, Storage, Edge Functions, Realtime) |
| **Auth** | Apple Sign In (primary), Phone number (secondary) |
| **Push Notifications** | APNs via Supabase Edge Functions |
| **Image Storage** | Supabase Storage (R2-backed) |
| **Analytics** | TelemetryDeck (privacy-first) |
| **Payments** | StoreKit 2 (subscriptions) |
| **CI/CD** | Xcode Cloud |

---

## Design System

### Color Palette

The design language is **"quiet luxury"** — think Aesop, Byredo, The Row. Muted, sophisticated, never flashy.

#### Primary Palette

```
background:        #0D0D0F    // Near-black with cool undertone
surfacePrimary:    #161619    // Elevated surface
surfaceSecondary:  #1C1C20    // Cards, modals
surfaceTertiary:   #232328    // Input fields, hover states
```

#### Accent — Warm Ivory/Champagne (NOT gold/yellow)

```
accent:            #D4C5A9    // Primary accent — warm ivory
accentLight:       #E8DCC8    // Hover/highlight state
accentMuted:       #A89B82    // Secondary accent, subtle elements
accentSubtle:      rgba(212, 197, 169, 0.08)  // Tinted backgrounds
```

#### Text

```
textPrimary:       #F2F0ED    // Warm white
textSecondary:     #8A877F    // Muted text
textTertiary:      #5C5955    // Disabled/placeholder
textAccent:        #D4C5A9    // Accent text
```

#### Semantic

```
success:           #7BAE7F    // Sage green
error:             #C47070    // Muted rose
warning:           #C4A870    // Warm amber
info:              #7099AE    // Steel blue
```

#### Borders & Dividers

```
borderSubtle:      rgba(255, 255, 255, 0.06)
borderMedium:      rgba(255, 255, 255, 0.10)
borderAccent:      rgba(212, 197, 169, 0.25)
```

### Typography

System fonts with specific weights for performance and native feel:

| Style | Font | Weight | Tracking | Usage |
|---|---|---|---|---|
| **Display** | `.system(.largeTitle, design: .serif)` | `.light` or `.regular` | 4–8pt (uppercase) | App name, hero text |
| **Headings** | `.system(.title, design: .serif)` | `.regular` | 0–1pt | Section titles, names |
| **Body** | `.system(.body, design: .default)` | `.regular` | 0 | Descriptions, bios, messages |
| **Caption** | `.system(.caption, design: .default)` | `.medium` | 2–4pt (uppercase) | Labels, tags, metadata |

### Design Principles

1. **Generous whitespace** — Let content breathe. Minimum 24pt margins, 16pt between elements.
2. **Subtle animations** — Gentle fades, soft springs. Never bouncy or playful. Use `.easeInOut` with 0.3–0.5s duration.
3. **No borders where shadows work** — Prefer elevation via subtle shadows over hard borders.
4. **Photography first** — Profile images are the hero. Full-bleed, high quality, minimal overlay.
5. **Haptic feedback** — Use `.light` impact on swipes, `.medium` on likes, `.success` notification on matches.

---

## Project Structure

```
Elite/
├── App/
│   ├── EliteApp.swift              // @main entry point
│   ├── AppDelegate.swift           // Push notification setup
│   └── ContentView.swift           // Root navigation
│
├── Core/
│   ├── Design/
│   │   ├── Theme.swift             // Colors, typography, spacing constants
│   │   ├── Components/
│   │   │   ├── EliteButton.swift
│   │   │   ├── EliteTextField.swift
│   │   │   ├── EliteCard.swift
│   │   │   ├── AvatarView.swift
│   │   │   ├── VerifiedBadge.swift
│   │   │   ├── TagChip.swift
│   │   │   └── GradientOverlay.swift
│   │   └── Modifiers/
│   │       ├── ShimmerModifier.swift
│   │       └── ParallaxModifier.swift
│   │
│   ├── Navigation/
│   │   ├── AppRouter.swift         // Central navigation coordinator
│   │   └── DeepLinkHandler.swift
│   │
│   └── Extensions/
│       ├── View+Extensions.swift
│       ├── Color+Theme.swift
│       └── Date+Formatting.swift
│
├── Features/
│   ├── Auth/
│   │   ├── Views/
│   │   │   ├── SplashView.swift
│   │   │   ├── OnboardingView.swift
│   │   │   ├── ReferralCodeView.swift
│   │   │   ├── WaitlistView.swift
│   │   │   ├── AppleSignInView.swift
│   │   │   └── PhoneAuthView.swift
│   │   ├── ViewModels/
│   │   │   └── AuthViewModel.swift
│   │   └── Services/
│   │       └── AuthService.swift
│   │
│   ├── Discovery/
│   │   ├── Views/
│   │   │   ├── DiscoveryView.swift       // Main card stack screen
│   │   │   ├── ProfileCardView.swift     // Swipeable card
│   │   │   ├── CardStackView.swift       // Card stack container
│   │   │   └── MatchView.swift           // Match celebration overlay
│   │   ├── ViewModels/
│   │   │   └── DiscoveryViewModel.swift
│   │   └── Services/
│   │       └── MatchService.swift
│   │
│   ├── Profile/
│   │   ├── Views/
│   │   │   ├── ProfileDetailView.swift   // Viewing someone's profile
│   │   │   ├── MyProfileView.swift       // Own profile / settings
│   │   │   ├── EditProfileView.swift
│   │   │   ├── PhotoPickerView.swift
│   │   │   └── ReferralShareView.swift
│   │   ├── ViewModels/
│   │   │   └── ProfileViewModel.swift
│   │   └── Services/
│   │       └── ProfileService.swift
│   │
│   ├── Messaging/
│   │   ├── Views/
│   │   │   ├── ChatListView.swift
│   │   │   ├── ChatView.swift            // Individual conversation
│   │   │   └── MessageBubble.swift
│   │   ├── ViewModels/
│   │   │   ├── ChatListViewModel.swift
│   │   │   └── ChatViewModel.swift
│   │   └── Services/
│   │       └── MessagingService.swift
│   │
│   └── Subscription/
│       ├── Views/
│       │   └── PaywallView.swift
│       ├── ViewModels/
│       │   └── SubscriptionViewModel.swift
│       └── Services/
│           └── StoreKitService.swift
│
├── Data/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Profile.swift
│   │   ├── Match.swift
│   │   ├── Message.swift
│   │   ├── ReferralCode.swift
│   │   └── Subscription.swift
│   ├── Repositories/
│   │   ├── UserRepository.swift
│   │   ├── MatchRepository.swift
│   │   └── MessageRepository.swift
│   └── Networking/
│       ├── SupabaseClient.swift
│       ├── SupabaseConfig.swift
│       └── ImageUploader.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── LaunchScreen.storyboard
    └── Info.plist
```

---

## Database Schema (Supabase / PostgreSQL)

### Profiles

```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    display_name TEXT NOT NULL,
    birth_date DATE NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'non_binary')),
    bio TEXT,
    title TEXT,                          -- "Art Director · Soho House"
    location TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    photos TEXT[] DEFAULT '{}',          -- Array of storage URLs (max 6)
    tags TEXT[] DEFAULT '{}',            -- Interest tags (max 8)
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    membership_status TEXT DEFAULT 'waitlist'
        CHECK (membership_status IN ('waitlist', 'active', 'suspended', 'banned')),
    referred_by UUID REFERENCES profiles(id),
    waitlist_position INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Referral Codes

```sql
CREATE TABLE referral_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,           -- 6 char alphanumeric
    owner_id UUID REFERENCES profiles(id) NOT NULL,
    used_by UUID REFERENCES profiles(id),
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Swipes / Actions

```sql
CREATE TABLE swipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swiper_id UUID REFERENCES profiles(id) NOT NULL,
    swiped_id UUID REFERENCES profiles(id) NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('like', 'pass', 'superlike')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(swiper_id, swiped_id)
);
```

### Matches

```sql
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID REFERENCES profiles(id) NOT NULL,
    user2_id UUID REFERENCES profiles(id) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    matched_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);
```

### Messages

```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES matches(id) NOT NULL,
    sender_id UUID REFERENCES profiles(id) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Reports

```sql
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES profiles(id) NOT NULL,
    reported_id UUID REFERENCES profiles(id) NOT NULL,
    reason TEXT NOT NULL,
    details TEXT,
    status TEXT DEFAULT 'pending'
        CHECK (status IN ('pending', 'reviewed', 'resolved')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Mutual Connections

```sql
CREATE TABLE connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID REFERENCES profiles(id) NOT NULL,
    user2_id UUID REFERENCES profiles(id) NOT NULL,
    source TEXT,                         -- 'instagram', 'contacts', 'referral'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);
```

### Row Level Security

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;

-- Users can read active profiles
CREATE POLICY "Read active profiles" ON profiles
    FOR SELECT USING (is_active = TRUE);

-- Users can update own profile
CREATE POLICY "Update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert own swipes
CREATE POLICY "Insert own swipes" ON swipes
    FOR INSERT WITH CHECK (auth.uid() = swiper_id);

-- Users can read own matches
CREATE POLICY "Read own matches" ON matches
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Users can read/write messages in their matches
CREATE POLICY "Read own messages" ON messages
    FOR SELECT USING (
        match_id IN (
            SELECT id FROM matches
            WHERE user1_id = auth.uid() OR user2_id = auth.uid()
        )
    );

CREATE POLICY "Send messages in matches" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        match_id IN (
            SELECT id FROM matches
            WHERE (user1_id = auth.uid() OR user2_id = auth.uid()) AND is_active = TRUE
        )
    );
```

### Indexes

```sql
CREATE INDEX idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX idx_swipes_swiped ON swipes(swiped_id);
CREATE INDEX idx_matches_users ON matches(user1_id, user2_id);
CREATE INDEX idx_messages_match ON messages(match_id, created_at DESC);
CREATE INDEX idx_profiles_status ON profiles(membership_status) WHERE is_active = TRUE;
CREATE INDEX idx_referral_codes_code ON referral_codes(code) WHERE is_used = FALSE;
```

---

## Features & Roadmap

### P0 — MVP (Launch)

- [ ] Apple Sign In authentication
- [ ] Referral code validation & entry
- [ ] Waitlist system with position tracking
- [ ] Profile creation (photos, bio, title, tags)
- [ ] Discovery card stack with swipe gestures
- [ ] Like / Pass / Superlike actions
- [ ] Match detection & celebration screen
- [ ] 1-to-1 real-time messaging (Supabase Realtime)
- [ ] Push notifications (new match, new message)
- [ ] Basic reporting system
- [ ] Subscription paywall (StoreKit 2)

### P1 — Post-Launch

- [ ] Profile verification (ID + selfie check)
- [ ] Mutual connections display
- [ ] Read receipts in chat
- [ ] Photo messages
- [ ] Profile prompts ("My ideal Sunday is...")
- [ ] Discovery filters (age, location, interests)
- [ ] Block user functionality
- [ ] Invite friends screen (share referral code)

### P2 — Growth

- [ ] Events & experiences feature
- [ ] Voice notes in chat
- [ ] Video calling
- [ ] Profile boost (subscription perk)
- [ ] Weekly curated suggestions
- [ ] Instagram integration for profile
- [ ] Incognito mode (subscription perk)

---

## Referral System

Every active member gets **3 referral codes per month**.

| Step | Action |
|---|---|
| 1 | Code is validated against `referral_codes` table |
| 2 | If valid — user skips waitlist, `membership_status = 'active'` |
| 3 | If no code — user enters waitlist, `membership_status = 'waitlist'` |
| 4 | Referrer gets notified that their invite was used |
| 5 | Used codes are marked `is_used = TRUE` |

**Code format:** 6 characters, alphanumeric, uppercase (e.g., `ELT7K2`)

---

## Subscription Tiers

### FREE (after acceptance)

- 5 likes per day
- See who liked you (blurred)
- Basic messaging

### ÉLITE+ — $29.99/month

- Unlimited likes
- 3 Superlikes per day
- See who liked you (clear)
- Advanced filters
- Read receipts
- Priority in discovery queue
- 5 referral codes per month (instead of 3)

### ÉLITE BLACK — $49.99/month

- Everything in ÉLITE+
- Incognito mode
- Profile boost (1x weekly)
- Video calling
- Priority support
- 10 referral codes per month
- Early access to events

---

## Discovery Algorithm

The discovery feed prioritizes:

1. **Mutual connections** (highest priority)
2. **Overlapping interest tags**
3. **Recently active users**
4. **Geographic proximity** (configurable radius)
5. **Users who already liked you** (subtle boost)

**Never show:** already swiped profiles, blocked users, reported users, inactive profiles.

---

## Development Guidelines

### Code Style

- Use SwiftUI previews for every view
- Prefer `@Observable` (iOS 17+) over `ObservableObject`
- Use `async/await` for all async operations
- Keep views under 100 lines — extract subviews aggressively
- Name files exactly as the struct/class they contain

### Error Handling

- Show user-friendly error messages (never raw error strings)
- Use `.alert` modifiers for critical errors
- Implement retry logic for network requests
- Cache profiles locally for offline browsing

### Performance

- Lazy load images with `AsyncImage` + caching
- Prefetch next 3 profiles in discovery stack
- Paginate message history (20 messages per page)
- Use `@Sendable` and proper concurrency

### Security

- Never store sensitive data in `UserDefaults`
- Use Keychain for tokens
- Validate referral codes server-side only
- Implement rate limiting on swipes via Edge Functions
- All database access through RLS policies

---

## Environment Variables

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key  // Only in Edge Functions
BUNDLE_ID=com.elite.dating
TEAM_ID=your-apple-team-id
```

---

## Getting Started

1. Clone the repo
2. Open `Elite.xcodeproj` in Xcode 15+
3. Set up Supabase project and run the SQL migrations
4. Add Supabase credentials to `SupabaseConfig.swift`
5. Configure Apple Sign In capability in Xcode
6. Run on simulator or device (iOS 17+)

---

## Implementation Notes

- Start with Auth flow first (Splash → Onboarding → Referral → Waitlist/Main)
- Build the Design System (`Theme.swift` + components) before features
- Use SF Symbols for icons where possible
- Test on iPhone 15 Pro simulator as primary device
- The app should feel like opening a luxury brand's app — slow, deliberate, beautiful
- Every transition should have a subtle animation
- Haptic feedback on all interactive elements

---

## License

Proprietary. All rights reserved.
