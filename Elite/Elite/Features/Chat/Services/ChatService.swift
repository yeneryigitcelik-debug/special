import Foundation

final class ChatService {
    private let api = APIClient.shared
    private let wsManager = WebSocketManager.shared

    func fetchMatches() async throws -> [Match] {
        let matches: [Match] = try await api.request(.GET, path: "/api/v1/matches")
        return matches
    }

    func fetchMessages(for matchId: UUID, limit: Int = 50, before: Date? = nil) async throws -> [Message] {
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let before {
            queryItems.append(URLQueryItem(name: "before", value: ISO8601DateFormatter().string(from: before)))
        }

        let messages: [Message] = try await api.request(
            .GET,
            path: "/api/v1/matches/\(matchId.uuidString)/messages",
            queryItems: queryItems
        )
        return messages
    }

    func sendMessage(matchId: UUID, content: String) async throws -> Message {
        let body = SendMessageRequest(content: content, messageType: "text")
        let message: Message = try await api.request(
            .POST,
            path: "/api/v1/matches/\(matchId.uuidString)/messages",
            body: body
        )
        return message
    }

    @MainActor
    func subscribeToMessages(matchId: UUID, onMessage: @escaping (Message) -> Void) {
        if !wsManager.isConnected {
            wsManager.connect()
            wsManager.startPing()
        }
        wsManager.subscribe(matchId: matchId, onMessage: onMessage)
    }

    @MainActor
    func unsubscribe(matchId: UUID) {
        wsManager.unsubscribe(matchId: matchId)
    }

    func markMessagesAsRead(matchId: UUID) async throws {
        try await api.requestVoid(.PUT, path: "/api/v1/matches/\(matchId.uuidString)/messages/read")
    }

    func fetchProfile(userId: UUID) async throws -> Profile {
        let profile: Profile = try await api.request(.GET, path: "/api/v1/profiles/\(userId.uuidString)")
        return profile
    }
}

private struct SendMessageRequest: Codable {
    let content: String
    let messageType: String
}
