import SwiftUI

enum AppTab: Hashable {
    case home
    case messages
    case tasks
    case split
    case more
}

struct AppShellView: View {
    let onSignOut: () -> Void

    var body: some View {
        MainTabView(onSignOut: onSignOut)
    }
}

#Preview {
    AppShellView(onSignOut: {})
        .environmentObject(HiveSpaceStore.sample)
}
