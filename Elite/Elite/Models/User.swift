import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    var displayName: String
    var birthdate: Date
    var gender: String?
    var bio: String?
    var title: String?
    var locationCity: String?
    var locationLat: Double?
    var locationLon: Double?
    var photoURLs: [String]
    var interestTags: [String]
    var isVerified: Bool
    var membershipStatus: MembershipStatus
    var subscriptionTier: SubscriptionTier
    var referredBy: UUID?
    var waitlistPosition: Int?
    var isActive: Bool
    var lastActiveAt: Date
    var createdAt: Date
    var updatedAt: Date

    enum MembershipStatus: String, Codable {
        case waitlist, active, suspended, banned
    }

    enum SubscriptionTier: String, Codable {
        case free, plus, black
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case birthdate
        case gender, bio, title
        case locationCity = "location_city"
        case locationLat = "location_lat"
        case locationLon = "location_lon"
        case photoURLs = "photo_urls"
        case interestTags = "interest_tags"
        case isVerified = "is_verified"
        case membershipStatus = "membership_status"
        case subscriptionTier = "subscription_tier"
        case referredBy = "referred_by"
        case waitlistPosition = "waitlist_position"
        case isActive = "is_active"
        case lastActiveAt = "last_active_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var age: Int { birthdate.age }

    var primaryPhotoURL: String? { photoURLs.first }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
