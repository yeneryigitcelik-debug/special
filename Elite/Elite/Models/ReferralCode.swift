import Foundation

struct ReferralCode: Codable, Identifiable {
    let id: UUID
    let ownerId: UUID
    let code: String
    var isUsed: Bool
    var usedBy: UUID?
    var usedAt: Date?
    let expiresAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case code
        case isUsed = "is_used"
        case usedBy = "used_by"
        case usedAt = "used_at"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }

    var isExpired: Bool {
        expiresAt < Date()
    }

    var isValid: Bool {
        !isUsed && !isExpired
    }
}
