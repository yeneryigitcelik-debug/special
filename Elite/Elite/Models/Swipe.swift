import Foundation

struct Swipe: Codable, Identifiable {
    let id: UUID
    let swiperId: UUID
    let swipedId: UUID
    let action: SwipeAction
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case swiperId = "swiper_id"
        case swipedId = "swiped_id"
        case action
        case createdAt = "created_at"
    }
}

enum SwipeAction: String, Codable {
    case like, pass, superlike
}
