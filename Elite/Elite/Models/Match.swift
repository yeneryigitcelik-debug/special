import Foundation

struct Match: Codable, Identifiable, Equatable {
    let id: UUID
    let user1Id: UUID
    let user2Id: UUID
    var isActive: Bool
    let matchedAt: Date

    var otherProfile: Profile?

    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case isActive = "is_active"
        case matchedAt = "matched_at"
    }

    func otherUserId(currentUserId: UUID) -> UUID {
        user1Id == currentUserId ? user2Id : user1Id
    }

    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.id == rhs.id
    }
}
