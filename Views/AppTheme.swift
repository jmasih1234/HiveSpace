import SwiftUI

// MARK: - Design Tokens

/// Semantic color tokens that adapt between light and dark mode.
/// The light palette is warm, residential, and editorial.
/// The dark palette is cinematic, near-black, and intimate.
enum HiveColor {

    // MARK: Surfaces

    /// Light: warm ivory. Dark: near-black.
    static let background = Color(light: Color(hex: 0xFAF7F2), dark: Color(hex: 0x0B0D0E))

    /// Light: white. Dark: dark charcoal.
    static let surface = Color(light: .white, dark: Color(hex: 0x15191B))

    /// Light: warm sand. Dark: elevated charcoal.
    static let surfaceElevated = Color(light: Color(hex: 0xF5E8DF), dark: Color(hex: 0x1D2224))

    // MARK: Text

    /// Light: charcoal. Dark: warm off-white.
    static let textPrimary = Color(light: Color(hex: 0x2E2E2E), dark: Color(hex: 0xF2EEE8))

    /// Light: warm gray. Dark: muted warm gray.
    static let textSecondary = Color(light: Color(hex: 0x7A7067), dark: Color(hex: 0x8A837A))

    // MARK: Border

    /// Light: stone at 30%. Dark: warm charcoal.
    static let border = Color(light: Color(red: 0.85, green: 0.83, blue: 0.80, opacity: 0.30), dark: Color(hex: 0x2A2725))

    // MARK: Brand

    /// Peach — the signature HiveSpace accent.
    /// Use selectively: primary buttons, selected nav, important actions.
    static let brand = Color(light: Color(hex: 0xE8856F), dark: Color(hex: 0xF3A58F))

    /// Subtle brand tint for backgrounds (12% light, 8% dark).
    static let brandSubtle = Color(light: Color(red: 0.91, green: 0.52, blue: 0.44, opacity: 0.12), dark: Color(red: 0.95, green: 0.65, blue: 0.56, opacity: 0.08))

    // MARK: Semantic Status

    /// Sage — completed, healthy, positive.
    static let sage = Color(red: 0.65, green: 0.72, blue: 0.62)

    /// Honey — due soon, warning.
    static let honey = Color(red: 0.83, green: 0.66, blue: 0.33)

    /// Clay — overdue, attention, destructive.
    static let clay = Color(red: 0.77, green: 0.56, blue: 0.48)

    /// Muted purple — recurring items only.
    static let recurring = Color(red: 0.61, green: 0.56, blue: 0.77)

    /// Legacy pink — extremely restrained secondary accent.
    static let pinkLegacy = Color(red: 0.83, green: 0.45, blue: 0.55)

    /// System red for destructive actions.
    static let destructive = Color(red: 0.90, green: 0.34, blue: 0.38)

    /// Green for success states (settlements confirmed, etc.).
    static let success = Color(red: 0.40, green: 0.72, blue: 0.45)
}

// MARK: - Fallback Aliases (backwards compatibility)

extension HiveColor {
    static var backgroundFallback: Color { background }
    static var surfaceFallback: Color { surface }
    static var surfaceElevatedFallback: Color { surfaceElevated }
    static var textPrimaryFallback: Color { textPrimary }
    static var textSecondaryFallback: Color { textSecondary }
    static var borderFallback: Color { border }
    static var brandFallback: Color { brand }
    static var brandSubtleFallback: Color { brandSubtle }
}

// MARK: - Typography

enum HiveFont {
    /// Editorial serif — screen titles, house names, emotional headlines.
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Body sans-serif — everything else.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Monospaced — codes, financial figures.
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // Preset sizes
    static let screenTitle = serif(28, weight: .semibold)
    static let sectionTitle = body(18, weight: .semibold)
    static let cardTitle = body(16, weight: .medium)
    static let bodyRegular = body(15, weight: .regular)
    static let bodyMedium = body(15, weight: .medium)
    static let caption = body(13, weight: .regular)
    static let captionMedium = body(13, weight: .medium)
    static let label = body(11, weight: .semibold)
    static let smallDetail = body(12, weight: .regular)
}

// MARK: - Spacing

enum HiveSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius

enum HiveRadius {
    /// Small controls (tags, badges).
    static let sm: CGFloat = 8
    /// Rows, small surfaces.
    static let md: CGFloat = 10
    /// Cards.
    static let card: CGFloat = 14
    /// Large feature surfaces.
    static let lg: CGFloat = 16
    /// Buttons.
    static let button: CGFloat = 10
}

// MARK: - Legacy Compatibility

/// Maps old HiveTheme references to new tokens so existing views
/// continue to compile while we migrate screen-by-screen.
enum HiveTheme {
    static var background: Color { HiveColor.background }
    static var surface: Color { HiveColor.surface }
    static var surfaceSoft: Color { HiveColor.surfaceElevated }
    static var border: Color { HiveColor.border }
    static var textPrimary: Color { HiveColor.textPrimary }
    static var textSecondary: Color { HiveColor.textSecondary }
    static var pink: Color { HiveColor.brand }
    static var magenta: Color { HiveColor.pinkLegacy }
    static var purple: Color { HiveColor.recurring }
    static var green: Color { HiveColor.success }
    static var yellow: Color { HiveColor.honey }
    static var red: Color { HiveColor.destructive }
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [HiveColor.brand, HiveColor.brand.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [HiveColor.backgroundFallback, HiveColor.backgroundFallback],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Shared Components

struct HiveScreen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            HiveColor.backgroundFallback
                .ignoresSafeArea()

            VStack(spacing: 0) {
                content
            }
        }
    }
}

struct HiveCard<Content: View>: View {
    var padding: CGFloat = HiveSpacing.lg
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.md) {
            content
        }
        .padding(padding)
        .background(HiveColor.surfaceFallback)
        .overlay {
            RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous)
                .strokeBorder(HiveColor.borderFallback, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous))
    }
}

struct HiveSectionTitle: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(HiveFont.label)
                .tracking(1.4)
                .foregroundStyle(HiveColor.textSecondaryFallback)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HiveColor.brandFallback)
            }
        }
    }
}

struct HivePrimaryButtonStyle: ButtonStyle {
    /// Peach background, charcoal text — matching the HiveSpace design system.
    private let buttonText = Color(light: Color(hex: 0x2E2E2E), dark: Color(hex: 0x1A1A1A))

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HiveFont.body(15, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: HiveRadius.button, style: .continuous)
                    .fill(HiveColor.brandFallback.opacity(configuration.isPressed ? 0.8 : 1))
            )
            .foregroundStyle(buttonText)
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.button, style: .continuous))
    }
}

struct HiveGhostButtonStyle: ButtonStyle {
    var color: Color = HiveColor.textSecondaryFallback

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HiveFont.body(13, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: HiveRadius.button, style: .continuous)
                    .fill(HiveColor.surfaceFallback.opacity(configuration.isPressed ? 0.8 : 0.5))
            )
            .overlay {
                RoundedRectangle(cornerRadius: HiveRadius.button, style: .continuous)
                    .strokeBorder(HiveColor.borderFallback, lineWidth: 1)
            }
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.button, style: .continuous))
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

// MARK: - Color Utilities

extension Color {
    /// Create a color from a hex integer (e.g. 0xFAF7F2).
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    /// Adaptive color that switches between light and dark appearances.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
