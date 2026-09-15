import SwiftUI

enum HiveTheme {
    static let background = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let surface = Color.white
    static let surfaceSoft = Color(red: 0.95, green: 0.92, blue: 0.98)
    static let border = Color(red: 0.24, green: 0.10, blue: 0.36).opacity(0.08)
    static let textPrimary = Color(red: 0.14, green: 0.08, blue: 0.22)
    static let textSecondary = Color(red: 0.40, green: 0.34, blue: 0.49)
    static let pink = Color(red: 0.95, green: 0.26, blue: 0.63)
    static let magenta = Color(red: 0.78, green: 0.30, blue: 0.84)
    static let purple = Color(red: 0.51, green: 0.34, blue: 0.96)
    static let green = Color(red: 0.25, green: 0.82, blue: 0.52)
    static let yellow = Color(red: 0.95, green: 0.72, blue: 0.18)
    static let red = Color(red: 0.96, green: 0.37, blue: 0.45)
    static let accentGradient = LinearGradient(
        colors: [pink, magenta, purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let screenGradient = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.98, blue: 0.96),
            Color(red: 0.96, green: 0.94, blue: 0.98)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct HiveScreen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            HiveTheme.screenGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                content
            }
        }
    }
}

struct HiveCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .background(HiveTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(HiveTheme.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct HiveSectionTitle: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(HiveTheme.textSecondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(HiveTheme.pink)
            }
        }
    }
}

struct HivePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HiveTheme.accentGradient.opacity(configuration.isPressed ? 0.75 : 1))
            )
            .foregroundStyle(.white)
    }
}

struct HiveGhostButtonStyle: ButtonStyle {
    var color: Color = HiveTheme.textSecondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white.opacity(configuration.isPressed ? 0.05 : 0.03))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(HiveTheme.border, lineWidth: 1)
            }
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct HiveStatusDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
    }
}
