# CLAUDE.md - ELITE Project Reference

## Project Overview

ELITE is an invite-only premium dating app for iOS 17+. Built with SwiftUI and Swift 5.9.
Bundle ID: `com.elite.dating`

## Architecture

MVVM with feature-based modules. Each feature (Auth, Chat, Discovery, Profile, Subscription) contains its own Services/, ViewModels/, and Views/ subdirectories.

## Tech Stack

- **UI**: SwiftUI (iOS 17+)
- **Backend**: Supabase (auth, database, realtime, storage)
- **Payments**: StoreKit 2
- **Image Loading**: Nuke / NukeUI (LazyImage)
- **SPM Dependencies**:
  - `supabase-swift` 2.0+ (https://github.com/supabase/supabase-swift)
  - `Nuke` 12.0+ (https://github.com/kean/Nuke)

## Project Structure

```
Elite/
  App/                  # EliteApp.swift, ContentView.swift, AppDelegate.swift
  Core/
    Design/
      Theme.swift       # EliteFont, EliteSpacing, EliteRadius, EliteShadow, EliteAnimation
      Components/       # EliteButton, EliteCard, EliteTextField, AvatarView, TagChip, etc.
      Modifiers/        # ShimmerModifier, ParallaxModifier
    Extensions/         # Color+Theme, Date+Formatting, View+Extensions
    Navigation/         # AppRouter, DeepLinkHandler
    Networking/         # SupabaseManager, APIError, NetworkMonitor
  Features/
    Auth/               # Apple Sign In, referral code entry
    Chat/               # Real-time messaging via Supabase Realtime
    Discovery/          # Card swipe UI
    Profile/            # Profile editing, photo management
    Subscription/       # StoreKit 2 paywall (free/plus/black)
  Models/               # Profile, User, Match, Message, Swipe, ReferralCode, Subscription
  Resources/
    Assets.xcassets
    Fonts/              # PlayfairDisplay, CormorantGaramond
    Info.plist
schema.sql              # Full database schema with RLS policies
```

## Design System -- "Quiet Luxury"

Aesthetic inspired by Aesop, The Row, Byredo. Warm darks, muted golds, understated elegance.

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| `eliteBackground` | `#1A1814` | App background (always use this) |
| `eliteSurface` | `#242019` | Cards, sheets |
| `eliteSurfaceElevated` | `#2E2A22` | Elevated surfaces |
| `eliteAccent` | `#D4C5A9` | Primary accent, CTAs |
| `eliteAccentMuted` | `#A89878` | Secondary accent |
| `eliteTextPrimary` | `#F5F0E8` | Primary text |
| `eliteTextSecondary` | `#9C9488` | Secondary text |
| `eliteTextTertiary` | `#6B6560` | Tertiary/placeholder text |
| `eliteSuccess` | `#7A9E7E` | Success states |
| `eliteError` | `#C47D7D` | Error states |
| `eliteDivider` | `#2E2A22` | Dividers, borders |

### Typography (EliteFont)

- **Display**: PlayfairDisplay-Bold (34/28pt), PlayfairDisplay-Regular (24pt)
- **Headline/Body**: CormorantGaramond-Medium (22/18pt), CormorantGaramond-Regular (17/15pt), CormorantGaramond-Light (13pt)
- **Labels/UI**: System font, medium weight (15/13/11pt)

### Spacing (EliteSpacing)

`xs: 4` | `sm: 8` | `md: 16` | `lg: 24` | `xl: 32` | `xxl: 48` | `xxxl: 64`

### Corner Radius (EliteRadius)

`small: 8` | `medium: 12` | `large: 16` | `xl: 24`

### Animation (EliteAnimation)

All easeInOut: `.smooth` (0.3s), `.medium` (0.4s), `.slow` (0.5s). Never use bouncy animations. There is also `.spring` (interpolatingSpring, stiffness 200, damping 20) for physics-based motion.

## Database Schema

All tables have RLS enabled. See `schema.sql` for full policies and indexes.

- **profiles**: id (UUID, PK), display_name, birthdate, gender, bio, title, location_city, location_lat/lon, photo_urls (TEXT[]), interest_tags (TEXT[]), is_verified, membership_status (waitlist/active/suspended/banned), subscription_tier (free/plus/black), referred_by, waitlist_position, is_active, last_active_at, created_at, updated_at
- **referral_codes**: id, owner_id, code (UNIQUE), is_used, used_by, used_at, expires_at, created_at
- **swipes**: id, swiper_id, swiped_id, action (like/pass/superlike), created_at -- UNIQUE(swiper_id, swiped_id)
- **matches**: id, user1_id, user2_id, is_active, matched_at -- UNIQUE(user1_id, user2_id)
- **messages**: id, match_id, sender_id, content, message_type (text/image/voice), is_read, created_at -- Realtime enabled

Storage bucket: `profile-photos` (public, user-scoped upload/delete)

## Auth Flow

Apple Sign In --> Referral Code Validation --> membership_status set to `active` (valid code) or `waitlist` (no code)

## Key Features

- **Discovery**: Card swipe interface (like/pass/superlike)
- **Chat**: Real-time messaging via Supabase Realtime (messages table)
- **Referral System**: Invite codes with expiration, single-use
- **Subscriptions**: Three tiers -- free, plus, black (StoreKit 2)

## Development Guidelines

1. **Always use design tokens** from `Theme.swift`: `EliteFont`, `EliteSpacing`, `EliteRadius`, `EliteShadow`, `EliteAnimation`. Never hardcode colors, spacing, or font values.
2. **Remote images**: Always use NukeUI `LazyImage`. Never use `AsyncImage`.
3. **ViewModel pattern**: All ViewModels must be `@MainActor` classes with `@Observable` or `ObservableObject`.
4. **Haptic feedback**:
   - `.light` for swipe gestures
   - `.medium` for likes
   - `.success` for matches
5. **Backgrounds**: Always use `Color.eliteBackground`. No white or system backgrounds.
6. **Navigation**: Custom navigation only. No default iOS navigation bars.
7. **Components**: Use `EliteButton`, `EliteCard`, `EliteTextField` from Core/Design/Components/ before building custom UI.

## Setup

1. Set Supabase credentials in `SupabaseManager.swift` (URL + anon key via environment or hardcoded for dev)
2. Run `schema.sql` in your Supabase project's SQL Editor
3. Add **Sign in with Apple** capability in Xcode
4. Ensure Supabase Apple OAuth provider is configured in the Supabase dashboard
