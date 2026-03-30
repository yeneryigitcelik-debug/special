import SwiftUI

@MainActor
final class ChatListViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var matches: [Match] = []
    @Published var newMatches: [Match] = []
    @Published var conversations: [Conversation] = []
    @Published var errorMessage: String?

    enum ViewState {
        case idle, loading, loaded, error
    }

    struct Conversation: Identifiable {
        let id: UUID
        let match: Match
        let profile: Profile
        var lastMessage: Message?
        var unreadCount: Int

        var sortDate: Date {
            lastMessage?.createdAt ?? match.matchedAt
        }
    }

    private let chatService = ChatService()

    func load() async {
        state = .loading
        do {
            let allMatches = try await chatService.fetchMatches()

            guard let currentUserId = TokenManager.shared.currentUserId else {
                state = .error
                return
            }

            var convos: [Conversation] = []
            var newMatchList: [Match] = []

            for match in allMatches {
                let otherUserId = match.otherUserId(currentUserId: currentUserId)
                let profile = try await chatService.fetchProfile(userId: otherUserId)

                if let otherProfile = match.otherProfile ?? Optional(profile) {
                    var matchWithProfile = match
                    matchWithProfile.otherProfile = otherProfile

                    // Check if there are any messages
                    let messages = try? await chatService.fetchMessages(for: match.id, limit: 1)
                    let lastMessage = messages?.last

                    if lastMessage != nil {
                        convos.append(Conversation(
                            id: match.id,
                            match: matchWithProfile,
                            profile: otherProfile,
                            lastMessage: lastMessage,
                            unreadCount: 0
                        ))
                    } else {
                        newMatchList.append(matchWithProfile)
                    }
                }
            }

            conversations = convos.sorted { $0.sortDate > $1.sortDate }
            newMatches = newMatchList
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }
}
