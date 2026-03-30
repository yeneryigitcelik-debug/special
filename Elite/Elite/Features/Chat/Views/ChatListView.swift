import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var searchText = ""

    var body: some View {
        ZStack {
            Color.eliteBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.state == .loading {
                    Spacer()
                    ProgressView()
                        .tint(.eliteAccent)
                    Spacer()
                } else if viewModel.conversations.isEmpty && viewModel.newMatches.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            if !viewModel.newMatches.isEmpty {
                                newMatchesSection
                            }

                            conversationsList
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .hideNavigationBar()
        .task {
            await viewModel.load()
        }
    }

    private var header: some View {
        VStack(spacing: EliteSpacing.md) {
            HStack {
                Text("Messages")
                    .font(EliteFont.displaySmall())
                    .foregroundColor(.eliteTextPrimary)
                Spacer()
            }
            .padding(.horizontal, EliteSpacing.lg)
            .padding(.top, EliteSpacing.sm)

            Rectangle()
                .fill(Color.eliteDivider)
                .frame(height: 0.5)
        }
    }

    private var newMatchesSection: some View {
        VStack(alignment: .leading, spacing: EliteSpacing.sm) {
            Text("New Matches")
                .font(EliteFont.labelMedium())
                .foregroundColor(.eliteTextSecondary)
                .padding(.horizontal, EliteSpacing.lg)
                .padding(.top, EliteSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: EliteSpacing.md) {
                    ForEach(viewModel.newMatches) { match in
                        NavigationLink {
                            if let profile = match.otherProfile {
                                ChatDetailView(
                                    matchId: match.id,
                                    otherProfile: profile
                                )
                            }
                        } label: {
                            newMatchItem(match)
                        }
                    }
                }
                .padding(.horizontal, EliteSpacing.lg)
            }

            Rectangle()
                .fill(Color.eliteDivider)
                .frame(height: 0.5)
                .padding(.top, EliteSpacing.sm)
        }
    }

    private func newMatchItem(_ match: Match) -> some View {
        VStack(spacing: EliteSpacing.xs) {
            AvatarView(
                imageURL: match.otherProfile?.primaryPhotoURL,
                size: 64
            )
            .overlay(
                Circle()
                    .strokeBorder(Color.eliteAccent.opacity(0.4), lineWidth: 1.5)
            )

            Text(match.otherProfile?.displayName ?? "")
                .font(EliteFont.labelSmall())
                .foregroundColor(.eliteTextPrimary)
                .lineLimit(1)
                .frame(width: 64)
        }
    }

    private var conversationsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.conversations) { convo in
                NavigationLink {
                    ChatDetailView(
                        matchId: convo.match.id,
                        otherProfile: convo.profile
                    )
                } label: {
                    conversationRow(convo)
                }

                Rectangle()
                    .fill(Color.eliteDivider)
                    .frame(height: 0.5)
                    .padding(.leading, 80)
            }
        }
    }

    private func conversationRow(_ convo: ChatListViewModel.Conversation) -> some View {
        HStack(spacing: EliteSpacing.md) {
            AvatarView(imageURL: convo.profile.primaryPhotoURL, size: 56)

            VStack(alignment: .leading, spacing: EliteSpacing.xs) {
                HStack {
                    Text(convo.profile.displayName)
                        .font(EliteFont.headlineMedium())
                        .foregroundColor(.eliteTextPrimary)

                    Spacer()

                    if let msg = convo.lastMessage {
                        Text(msg.createdAt.timeAgo)
                            .font(EliteFont.caption())
                            .foregroundColor(.eliteTextTertiary)
                    }
                }

                HStack {
                    Text(convo.lastMessage?.content ?? "Say hello!")
                        .font(EliteFont.bodyMedium())
                        .foregroundColor(.eliteTextSecondary)
                        .lineLimit(1)

                    Spacer()

                    if convo.unreadCount > 0 {
                        Text("\(convo.unreadCount)")
                            .font(EliteFont.labelSmall())
                            .foregroundColor(.eliteBackground)
                            .frame(width: 20, height: 20)
                            .background(Color.eliteAccent)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, EliteSpacing.lg)
        .padding(.vertical, EliteSpacing.sm + 4)
        .contentShape(Rectangle())
    }

    @EnvironmentObject var router: AppRouter

    private var emptyState: some View {
        VStack(spacing: EliteSpacing.lg) {
            Spacer()

            Image(systemName: "message")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.eliteTextTertiary)

            VStack(spacing: EliteSpacing.sm) {
                Text("No Messages Yet")
                    .font(EliteFont.headlineLarge())
                    .foregroundColor(.eliteTextPrimary)

                Text("Start swiping to make\nmeaningful connections")
                    .font(EliteFont.bodyMedium())
                    .foregroundColor(.eliteTextSecondary)
                    .multilineTextAlignment(.center)
            }

            EliteButton(title: "START SWIPING", style: .primary) {
                router.selectedTab = .discovery
            }
            .frame(width: 220)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ChatListView()
    }
}
