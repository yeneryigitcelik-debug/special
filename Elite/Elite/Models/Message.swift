import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    let matchId: UUID
    let senderId: UUID
    var content: String
    var messageType: MessageType
    var isRead: Bool
    let createdAt: Date

    enum MessageType: String, Codable {
        case text, image, voice
    }

    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case senderId = "sender_id"
        case content
        case messageType = "message_type"
        case isRead = "is_read"
        case createdAt = "created_at"
    }

    func isSentBy(_ userId: UUID) -> Bool {
        senderId == userId
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
