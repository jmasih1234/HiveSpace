import SwiftUI

struct ContentView: View {
    @StateObject private var store = HiveSpaceStore.sample
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                LaunchScreen()
            } else {
                AuthView()
                    .environmentObject(store)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isLoading)
        .overlay(alignment: .top) {
            if let toast = store.toastMessage {
                ToastView(message: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 60)
            }
        }
        .animation(.spring(response: 0.4), value: store.toastMessage)
        .task {
            // Try loading persisted data
            if let saved = await HiveSpaceStore.loadFromDisk() {
                store.account = saved.account
                store.allColonies = saved.allColonies
                store.currentUser = saved.currentUser
                store.colony = saved.colony
                store.tasks = saved.tasks
                store.expenses = saved.expenses
                store.activityEvents = saved.activityEvents
                store.healthScore = saved.healthScore
                store.choreWheels = saved.choreWheels
                store.nudges = saved.nudges
                store.joinRequests = saved.joinRequests
                store.settlementRequests = saved.settlementRequests
                store.eventSplits = saved.eventSplits
                store.semesterSnapshots = saved.semesterSnapshots
                store.messageChannels = saved.messageChannels
                store.messages = saved.messages
                store.directThreads = saved.directThreads
                store.callSessions = saved.callSessions
                store.trips = saved.trips
                store.availabilityPolls = saved.availabilityPolls
                store.teamWorkspace = saved.teamWorkspace
            }

            // Brief splash delay for polish
            try? await Task.sleep(for: .milliseconds(600))
            isLoading = false
        }
    }
}

// MARK: - Launch Screen

struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            HiveTheme.background
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HiveLogoMark(size: 80, shadowOpacity: 0.2)
                    .scaleEffect(scale)

                Text("HiveSpace")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)

                ProgressView()
                    .tint(HiveTheme.pink)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HiveTheme.green)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

#Preview {
    ContentView()
}
