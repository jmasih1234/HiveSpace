import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var selectedTab: AppTab = .home
    let onSignOut: () -> Void

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)

            NavigationStack {
                TasksView()
            }
            .tabItem { Label("Tasks", systemImage: "checklist") }
            .tag(AppTab.tasks)
            .badge(store.pendingTaskCount)

            NavigationStack {
                ExpensesView()
            }
            .tabItem { Label("Expenses", systemImage: "creditcard") }
            .tag(AppTab.expenses)
            .badge(store.unsettledExpenses.count)

            NavigationStack {
                CallView()
            }
            .tabItem { Label("Calls", systemImage: "phone") }
            .tag(AppTab.calls)
            .badge(store.activeCallSession == nil ? 0 : 1)

            NavigationStack {
                HouseView(onSignOut: onSignOut)
            }
            .tabItem { Label("House", systemImage: "building.2") }
            .tag(AppTab.house)

            NavigationStack {
                InboxView()
            }
            .tabItem { Label("Inbox", systemImage: "tray") }
            .tag(AppTab.inbox)
            .badge(store.totalUnreadMessages)
        }
        .tint(HiveColor.brandFallback)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = UIColor.clear

        let normalColor = UIColor(HiveColor.textSecondaryFallback)
        let selectedColor = UIColor(HiveColor.brandFallback)

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - House View

/// The House tab — colony identity, members, health, settings.
/// Replaces the old "More" tab.
struct HouseView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    let onSignOut: () -> Void
    @State private var showingSearch = false

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: HiveSpacing.lg) {
                    HivePageHeader(
                        eyebrow: store.colony.type.rawValue,
                        title: store.colony.name,
                        subtitle: "\(store.colony.memberCount) members"
                    ) {
                        HStack(spacing: HiveSpacing.sm) {
                            Button {
                                showingSearch = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(HiveColor.textSecondaryFallback)
                                    .frame(width: 34, height: 34)
                                    .background(HiveColor.surfaceFallback)
                                    .clipShape(RoundedRectangle(cornerRadius: HiveRadius.md, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: HiveRadius.md, style: .continuous)
                                            .strokeBorder(HiveColor.borderFallback, lineWidth: 1)
                                    }
                            }
                            ColonySwitcherButton()
                        }
                    }

                    // Profile card
                    HiveCard {
                        HStack(spacing: HiveSpacing.md) {
                            Circle()
                                .fill(HiveColor.brandSubtleFallback)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Text(String(store.currentUser.displayName.prefix(1)))
                                        .font(HiveFont.body(18, weight: .semibold))
                                        .foregroundStyle(HiveColor.brandFallback)
                                }
                            VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                                Text(store.currentUser.displayName)
                                    .font(HiveFont.cardTitle)
                                    .foregroundStyle(HiveColor.textPrimaryFallback)
                                Text(store.currentUser.shareableID)
                                    .font(HiveFont.caption)
                                    .foregroundStyle(HiveColor.textSecondaryFallback)
                            }
                            Spacer()
                        }
                    }

                    // Navigation links
                    NavigationLink {
                        FeedView()
                    } label: {
                        houseNavCard(
                            title: "Activity Feed",
                            subtitle: "Updates, nudges, and history",
                            icon: "bubble.left.and.bubble.right"
                        )
                    }

                    NavigationLink {
                        ColonyView(onSignOut: onSignOut)
                    } label: {
                        houseNavCard(
                            title: "Colony Settings",
                            subtitle: "Members, invites, and preferences",
                            icon: "person.3"
                        )
                    }

                    // Sign Out
                    Button("Sign Out", action: onSignOut)
                        .buttonStyle(HiveGhostButtonStyle(color: HiveColor.destructive))
                        .frame(maxWidth: .infinity)
                        .padding(.top, HiveSpacing.lg)
                }
                .padding(HiveSpacing.xxl)
            }
        }
        .navigationTitle("House")
        .sheet(isPresented: $showingSearch) {
            SearchView()
                .environmentObject(store)
        }
    }

    private func houseNavCard(title: String, subtitle: String, icon: String) -> some View {
        HiveCard {
            HStack(spacing: HiveSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HiveColor.brandFallback)
                    .frame(width: 38, height: 38)
                    .background(HiveColor.brandSubtleFallback)
                    .clipShape(RoundedRectangle(cornerRadius: HiveRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                    Text(title)
                        .font(HiveFont.cardTitle)
                        .foregroundStyle(HiveColor.textPrimaryFallback)
                    Text(subtitle)
                        .font(HiveFont.caption)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HiveColor.textSecondaryFallback)
            }
        }
    }
}

// MARK: - Inbox View

/// The Inbox tab — unified messaging and notifications.
struct InboxView: View {
    @EnvironmentObject private var store: HiveSpaceStore

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: HiveSpacing.lg) {
                    HivePageHeader(
                        title: "Inbox",
                        subtitle: store.totalUnreadMessages > 0
                            ? "\(store.totalUnreadMessages) unread"
                            : "All caught up"
                    )

                    if store.activeChannels.isEmpty {
                        HiveEmptyState(
                            title: "No messages yet",
                            message: "Start a conversation with your housemates.",
                            systemImage: "tray"
                        )
                    } else {
                        ForEach(store.activeChannels) { channel in
                            NavigationLink {
                                MessagingView()
                            } label: {
                                inboxRow(channel: channel)
                            }
                        }
                    }
                }
                .padding(HiveSpacing.xxl)
            }
        }
        .navigationTitle("Inbox")
    }

    private func inboxRow(channel: MessageChannel) -> some View {
        HStack(spacing: HiveSpacing.md) {
            Image(systemName: iconForChannel(channel.kind))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(HiveColor.textSecondaryFallback)
                .frame(width: 36, height: 36)
                .background(HiveColor.surfaceElevatedFallback)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                Text(channel.name.capitalized)
                    .font(HiveFont.bodyMedium)
                    .foregroundStyle(HiveColor.textPrimaryFallback)
                if let topic = channel.topic {
                    Text(topic)
                        .font(HiveFont.caption)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                        .lineLimit(1)
                }
            }

            Spacer()

            if channel.unreadCount > 0 {
                Text("\(channel.unreadCount)")
                    .font(HiveFont.label)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(HiveColor.brandFallback)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, HiveSpacing.sm)
    }

    private func iconForChannel(_ kind: MessageChannelKind) -> String {
        switch kind {
        case .general: return "bubble.left"
        case .tasks: return "checklist"
        case .expenses: return "creditcard"
        case .social: return "face.smiling"
        case .direct: return "person"
        }
    }
}

#Preview {
    MainTabView(onSignOut: {})
        .environmentObject(HiveSpaceStore.sample)
}

#Preview("House") {
    NavigationStack {
        HouseView(onSignOut: {})
            .environmentObject(HiveSpaceStore.sample)
    }
}

#Preview("Inbox") {
    NavigationStack {
        InboxView()
            .environmentObject(HiveSpaceStore.sample)
    }
}
