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
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(AppTab.home)

            NavigationStack {
                MessagingView()
            }
            .tabItem { Label("Messages", systemImage: "message.fill") }
            .tag(AppTab.messages)
            .badge(store.totalUnreadMessages)

            NavigationStack {
                TasksView()
            }
            .tabItem { Label("Tasks", systemImage: "checklist") }
            .tag(AppTab.tasks)
            .badge(store.pendingTaskCount)

            NavigationStack {
                ExpensesView()
            }
            .tabItem { Label("Split", systemImage: "creditcard.fill") }
            .tag(AppTab.split)
            .badge(store.unsettledExpenses.count)

            NavigationStack {
                MoreView(onSignOut: onSignOut)
            }
            .tabItem { Label("More", systemImage: "square.grid.2x2.fill") }
            .tag(AppTab.more)
        }
        .tint(HiveTheme.pink)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(HiveTheme.background.opacity(0.96))
            appearance.shadowColor = UIColor.clear
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(HiveTheme.textSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(HiveTheme.textSecondary)
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(HiveTheme.pink)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(HiveTheme.pink)
            ]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct MoreView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    let onSignOut: () -> Void
    @State private var showingSearch = false

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HivePageHeader(
                        eyebrow: "Hive",
                        title: store.account.hive.name,
                        subtitle: "\(store.account.subscriptionTier.rawValue) membership"
                    ) {
                        HStack(spacing: 10) {
                            Button {
                                showingSearch = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(HiveTheme.textSecondary)
                                    .frame(width: 34, height: 34)
                                    .background(HiveTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(HiveTheme.border, lineWidth: 1)
                                    }
                            }
                            ColonySwitcherButton()
                        }
                    }

                    HiveCard {
                        Text(store.currentUser.displayName)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)
                        Text(store.currentUser.shareableID)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(HiveTheme.textSecondary)
                    }

                    NavigationLink {
                        FeedView()
                    } label: {
                        moreCard(title: "Colony Feed", subtitle: "Activity, nudges, and updates", icon: "bubble.left.and.bubble.right.fill")
                    }

                    NavigationLink {
                        TripView()
                    } label: {
                        moreCard(title: "Trips", subtitle: "Itinerary, packing, and polls", icon: "suitcase.rolling.fill")
                    }

                    NavigationLink {
                        CallView()
                    } label: {
                        moreCard(title: "Calls", subtitle: "Incoming, active, and scheduled calls", icon: "video.fill")
                    }

                    NavigationLink {
                        AvailabilityView()
                    } label: {
                        moreCard(title: "Availability", subtitle: "Find meeting times across the colony", icon: "calendar.badge.clock")
                    }

                    NavigationLink {
                        ColonyView(onSignOut: onSignOut)
                    } label: {
                        moreCard(title: "Colony", subtitle: "Members, join requests, and semester mode", icon: "person.3.fill")
                    }

                    moreSectionTitle("Workspace")

                    ForEach(store.teamWorkspace.documents) { doc in
                        moreCard(title: doc.title, subtitle: "Updated \(doc.updatedAt.formatted(date: .abbreviated, time: .shortened))", icon: "doc.text.fill")
                    }

                    ForEach(store.teamWorkspace.calendarEvents) { event in
                        moreCard(title: event.title, subtitle: event.date.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
                    }

                    Button("Sign Out", action: onSignOut)
                        .buttonStyle(HivePrimaryButtonStyle())
                }
                .padding(24)
            }
        }
        .navigationTitle("More")
        .sheet(isPresented: $showingSearch) {
            SearchView()
                .environmentObject(store)
        }
    }

    private func moreSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .semibold, design: .serif))
            .foregroundStyle(HiveTheme.textPrimary)
    }

    private func moreCard(title: String, subtitle: String, icon: String) -> some View {
        HiveCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HiveTheme.pink)
                    .frame(width: 42, height: 42)
                    .background(HiveTheme.pink.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(HiveTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                }

                Spacer()
            }
        }
    }
}

#Preview {
    MainTabView(onSignOut: {})
        .environmentObject(HiveSpaceStore.sample)
}

#Preview("More") {
    NavigationStack {
        MoreView(onSignOut: {})
            .environmentObject(HiveSpaceStore.sample)
    }
}
