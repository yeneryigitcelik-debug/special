import SwiftUI

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(matchId: UUID, otherProfile: Profile) {
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(
            matchId: matchId,
            otherProfile: otherProfile
        ))
    }

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                chatNavBar

                if viewModel.state == .loading {
                    Spacer()
                    ProgressView().tint(.eliteAccent)
                    Spacer()
                } else {
                    messagesList
                }

                ChatInputBar(text: $viewModel.messageText) {
                    Task { await viewModel.sendMessage() }
                }
            }
        }
        .hideNavigationBar()
        .task {
            await viewModel.load()
        }
        .onDisappear {
            Task { await viewModel.disconnect() }
        }
    }

    private var chatNavBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: EliteSpacing.md) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.eliteTextPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                AvatarView(
                    imageURL: viewModel.otherProfile.primaryPhotoURL,
                    size: 36,
                    showOnlineIndicator: true,
                    isOnline: true
                )

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: EliteSpacing.xs) {
                        Text(viewModel.otherProfile.displayName)
                            .font(EliteFont.headlineMedium())
                            .foregroundColor(.eliteTextPrimary)

                        if viewModel.otherProfile.isVerified {
                            VerifiedBadge(size: 14)
                        }
                    }

                    Text("Online")
                        .font(EliteFont.caption())
                        .foregroundColor(.eliteSuccess)
                }

                Spacer()
            }
            .padding(.horizontal, EliteSpacing.md)
            .padding(.vertical, EliteSpacing.sm)

            Rectangle()
                .fill(Color.eliteDivider)
                .frame(height: 0.5)
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: EliteSpacing.sm) {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        let showTime = shouldShowTimestamp(at: index)

                        MessageBubble(
                            message: message,
                            isSent: !message.isSentBy(viewModel.otherProfile.id),
                            showTimestamp: showTime
                        )
                        .padding(.horizontal, EliteSpacing.md)
                        .id(message.id)
                    }

                    if viewModel.isTyping {
                        HStack {
                            TypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal, EliteSpacing.md)
                    }
                }
                .padding(.vertical, EliteSpacing.md)
                .padding(.bottom, EliteSpacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(EliteAnimation.smooth) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }

    private func shouldShowTimestamp(at index: Int) -> Bool {
        guard index > 0 else { return true }
        let current = viewModel.messages[index].createdAt
        let previous = viewModel.messages[index - 1].createdAt
        return current.timeIntervalSince(previous) > 300 // 5 minutes
    }
}
