import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var displayName: String
    var birthdate: Date
    var gender: String?
    var bio: String?
    var title: String?
    var locationCity: String?
    var photoURLs: [String]
    var interestTags: [String]
    var isVerified: Bool
    var subscriptionTier: User.SubscriptionTier

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case birthdate
        case gender, bio, title
        case locationCity = "location_city"
        case photoURLs = "photo_urls"
        case interestTags = "interest_tags"
        case isVerified = "is_verified"
        case subscriptionTier = "subscription_tier"
    }

    var age: Int { birthdate.age }
    var primaryPhotoURL: String? { photoURLs.first }
}
