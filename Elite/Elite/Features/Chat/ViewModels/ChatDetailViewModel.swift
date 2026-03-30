import SwiftUI

@MainActor
final class ChatDetailViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var errorMessage: String?
    @Published var isTyping = false

    enum ViewState {
        case idle, loading, loaded, error
    }

    let matchId: UUID
    let otherProfile: Profile
    private let chatService = ChatService()

    init(matchId: UUID, otherProfile: Profile) {
        self.matchId = matchId
        self.otherProfile = otherProfile
    }

    func load() async {
        state = .loading
        do {
            messages = try await chatService.fetchMessages(for: matchId)
            state = .loaded

            try? await chatService.markMessagesAsRead(matchId: matchId)

            chatService.subscribeToMessages(matchId: matchId) { [weak self] message in
                guard let self else { return }
                if !self.messages.contains(where: { $0.id == message.id }) {
                    withAnimation(EliteAnimation.smooth) {
                        self.messages.append(message)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }

    func sendMessage() async {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        messageText = ""

        do {
            let message = try await chatService.sendMessage(matchId: matchId, content: content)
            if !messages.contains(where: { $0.id == message.id }) {
                withAnimation(EliteAnimation.smooth) {
                    messages.append(message)
                }
            }
        } catch {
            errorMessage = "Failed to send message"
            messageText = content
        }
    }

    func disconnect() async {
        await chatService.unsubscribe(matchId: matchId)
    }
}
