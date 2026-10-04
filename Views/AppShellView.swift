import SwiftUI

enum AppTab: Hashable {
    case home
    case tasks
    case expenses
    case calls
    case house
    case inbox
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
