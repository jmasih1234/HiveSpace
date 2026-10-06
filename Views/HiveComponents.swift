import SwiftUI
import UIKit

// MARK: - Logo Mark

/// The HiveSpace logo — a simple house outline in the brand color.
struct HiveLogoMark: View {
    var size: CGFloat = 32
    var shadowOpacity: Double = 0.10

    var body: some View {
        ZStack {
            // House shape
            HiveHouseShape()
                .fill(HiveColor.brandFallback)
                .shadow(color: HiveColor.brandFallback.opacity(shadowOpacity), radius: size * 0.06, x: 0, y: size * 0.04)

            // Window detail
            RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                .fill(Color.white.opacity(0.45))
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(y: size * 0.10)
        }
        .frame(width: size, height: size)
    }
}

/// A simple house silhouette shape.
private struct HiveHouseShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Roof peak
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.08))
        // Roof right
        path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.42))
        // Wall right
        path.addLine(to: CGPoint(x: w * 0.90, y: h * 0.88))
        // Bottom right corner
        path.addQuadCurve(
            to: CGPoint(x: w * 0.84, y: h * 0.92),
            control: CGPoint(x: w * 0.90, y: h * 0.92)
        )
        // Bottom
        path.addLine(to: CGPoint(x: w * 0.16, y: h * 0.92))
        // Bottom left corner
        path.addQuadCurve(
            to: CGPoint(x: w * 0.10, y: h * 0.88),
            control: CGPoint(x: w * 0.10, y: h * 0.92)
        )
        // Wall left
        path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.42))
        path.closeSubpath()

        return path
    }
}

// MARK: - Page Header

/// Editorial page header with optional serif title.
struct HivePageHeader<Trailing: View>: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    var useSerif: Bool = true
    @ViewBuilder let trailing: Trailing

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        useSerif: Bool = true,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.useSerif = useSerif
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(HiveFont.caption)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                }

                Text(title)
                    .font(useSerif ? HiveFont.screenTitle : HiveFont.sectionTitle)
                    .foregroundStyle(HiveColor.textPrimaryFallback)

                if let subtitle {
                    Text(subtitle)
                        .font(HiveFont.caption)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                }
            }

            Spacer()
            trailing
        }
    }
}

// MARK: - Colony Switcher

struct ColonySwitcherButton: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var showingColonyPicker = false

    var body: some View {
        Button {
            showingColonyPicker = true
        } label: {
            HStack(spacing: 6) {
                Text(store.colony.emoji)
                    .font(.system(size: 16))
                Text(store.colony.name)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .font(HiveFont.captionMedium)
            .padding(.horizontal, HiveSpacing.md)
            .padding(.vertical, HiveSpacing.sm)
            .background(HiveColor.surfaceFallback)
            .foregroundStyle(HiveColor.textPrimaryFallback)
            .overlay {
                RoundedRectangle(cornerRadius: HiveRadius.button, style: .continuous)
                    .strokeBorder(HiveColor.borderFallback, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.button, style: .continuous))
        }
        .sheet(isPresented: $showingColonyPicker) {
            ColonyPickerSheet()
                .environmentObject(store)
        }
    }
}

struct ColonyPickerSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var newColonyName = ""
    @State private var newColonyType: ColonyType = .roommates

    var body: some View {
        NavigationStack {
            List {
                Section("Your Colonies") {
                    ForEach(store.allColonies) { colony in
                        Button {
                            store.switchColony(to: colony)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Text(colony.emoji)
                                    .font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(colony.name)
                                    Text(colony.type.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if colony.id == store.colony.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HiveColor.brandFallback)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Create Colony") {
                    TextField("New colony name", text: $newColonyName)
                    Picker("Type", selection: $newColonyType) {
                        ForEach(ColonyType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Button("Create") {
                        guard !newColonyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            return
                        }
                        store.createColony(named: newColonyName, type: newColonyType)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Colonies")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Colony Badge

struct ColonyBadge: View {
    let colonyName: String
    var size: CGFloat = 32

    var body: some View {
        HiveLogoMark(size: size, shadowOpacity: 0.08)
            .accessibilityLabel("\(colonyName) logo")
    }
}

// MARK: - Empty State

struct HiveEmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HiveCard {
            VStack(spacing: HiveSpacing.md) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(HiveColor.textSecondaryFallback)
                Text(title)
                    .font(HiveFont.sectionTitle)
                    .foregroundStyle(HiveColor.textPrimaryFallback)
                Text(message)
                    .font(HiveFont.caption)
                    .foregroundStyle(HiveColor.textSecondaryFallback)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Section Header

/// Reusable section header with serif title and optional trailing action.
struct HiveSectionHeader: View {
    let title: String
    var action: String?
    var onAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(HiveFont.sectionTitle)
                .foregroundStyle(HiveColor.textPrimaryFallback)
            Spacer()
            if let action, let onAction {
                Button(action) { onAction() }
                    .font(HiveFont.captionMedium)
                    .foregroundStyle(HiveColor.textSecondaryFallback)
            }
        }
    }
}

// MARK: - Health Indicator

/// Compact Hive Health display with sage-colored progress.
struct HiveHealthIndicator: View {
    let score: Int
    let grade: String
    var summary: String?

    private var progressColor: Color {
        switch score {
        case 80...100: return HiveColor.sage
        case 60..<80: return HiveColor.honey
        case 40..<60: return HiveColor.clay
        default: return HiveColor.destructive
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: HiveSpacing.sm) {
                Text("\(score)")
                    .font(HiveFont.serif(42, weight: .bold))
                    .foregroundStyle(HiveColor.textPrimaryFallback)
                Text("/ 100")
                    .font(HiveFont.caption)
                    .foregroundStyle(HiveColor.textSecondaryFallback)
                Spacer()
                Text(grade)
                    .font(HiveFont.captionMedium)
                    .foregroundStyle(HiveColor.textSecondaryFallback)
                    .padding(.horizontal, HiveSpacing.sm)
                    .padding(.vertical, HiveSpacing.xs)
                    .background(HiveColor.surfaceElevatedFallback)
                    .clipShape(RoundedRectangle(cornerRadius: HiveRadius.sm, style: .continuous))
            }

            ProgressView(value: Double(score), total: 100)
                .tint(progressColor)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            if let summary {
                Text(summary)
                    .font(HiveFont.caption)
                    .foregroundStyle(HiveColor.textSecondaryFallback)
            }
        }
    }
}

// MARK: - Task Row

/// Lightweight task row — no card wrapping.
struct HiveTaskRow: View {
    let title: String
    var subtitle: String?
    var statusColor: Color = HiveColor.textSecondaryFallback
    var statusLabel: String?
    var isCompleted: Bool = false
    var onToggle: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: HiveSpacing.md) {
            Button {
                onToggle?()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isCompleted ? HiveColor.sage : HiveColor.textSecondaryFallback)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                Text(title)
                    .font(HiveFont.bodyMedium)
                    .foregroundStyle(isCompleted ? HiveColor.textSecondaryFallback : HiveColor.textPrimaryFallback)
                    .strikethrough(isCompleted)

                if let subtitle {
                    Text(subtitle)
                        .font(HiveFont.caption)
                        .foregroundStyle(statusColor)
                }
            }

            Spacer()

            if let statusLabel {
                Text(statusLabel)
                    .font(HiveFont.label)
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.vertical, HiveSpacing.sm)
    }
}

// MARK: - Premium Visual Components

struct HiveAvatar: View {
    let name: String
    var size: CGFloat = 36
    var style: AvatarStyle = .warm

    enum AvatarStyle {
        case warm
        case dark
        case photo
    }

    private var fill: Color {
        switch style {
        case .warm:
            return HiveColor.brandSubtleFallback
        case .dark:
            return HiveColor.darkElevatedSurface
        case .photo:
            return Color.white.opacity(0.18)
        }
    }

    private var foreground: Color {
        switch style {
        case .warm:
            return HiveColor.brandFallback
        case .dark, .photo:
            return HiveColor.primaryLightText
        }
    }

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: size, height: size)
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(HiveFont.body(max(10, size * 0.38), weight: .semibold))
                    .foregroundStyle(foreground)
            }
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(style == .photo ? 0.30 : 0), lineWidth: 1)
            }
            .accessibilityLabel(name)
    }
}

struct HiveMemberStack: View {
    let names: [String]
    var size: CGFloat = 28
    var maxVisible = 4
    var style: HiveAvatar.AvatarStyle = .warm

    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(names.prefix(maxVisible).enumerated()), id: \.offset) { _, name in
                HiveAvatar(name: name, size: size, style: style)
                    .overlay {
                        Circle()
                            .strokeBorder(style == .photo ? Color.white.opacity(0.45) : HiveColor.backgroundFallback, lineWidth: 1.5)
                    }
            }

            let remaining = names.count - maxVisible
            if remaining > 0 {
                Text("+\(remaining)")
                    .font(HiveFont.label)
                    .foregroundStyle(style == .photo ? HiveColor.primaryLightText : HiveColor.textSecondaryFallback)
                    .frame(width: size, height: size)
                    .background(style == .photo ? Color.white.opacity(0.18) : HiveColor.surfaceElevatedFallback)
                    .clipShape(Circle())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(names.count) members")
    }
}

struct HivePhotoHero<Overlay: View>: View {
    let imageName: String
    var customImage: UIImage?
    let accessibilityLabel: String
    var height: CGFloat = 520
    var cornerRadius: CGFloat = HiveRadius.hero
    @ViewBuilder let overlay: Overlay

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroImage
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.62),
                    Color.black.opacity(0.20),
                    Color.black.opacity(0.56)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    HiveColor.deepEspresso.opacity(0.70),
                    Color.clear,
                    Color.black.opacity(0.64)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            overlay
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var heroImage: Image {
        if let customImage {
            return Image(uiImage: customImage)
        }

        return Image(imageName)
    }
}

struct HiveStatusChip: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = HiveColor.premiumAccent
    var style: ChipStyle = .photo
    var action: (() -> Void)?

    enum ChipStyle {
        case photo
        case warm
        case dark
    }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: HiveSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconForeground)
                    .frame(width: 26, height: 26)
                    .background(tint.opacity(style == .photo ? 0.95 : 0.16))
                    .clipShape(RoundedRectangle(cornerRadius: HiveRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HiveFont.label)
                        .foregroundStyle(secondaryForeground)
                        .lineLimit(1)
                    Text(value)
                        .font(HiveFont.captionMedium)
                        .foregroundStyle(primaryForeground)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, HiveSpacing.md)
            .padding(.vertical, HiveSpacing.sm)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HiveRadius.md, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private var background: Color {
        switch style {
        case .photo:
            return Color.black.opacity(0.28)
        case .warm:
            return HiveColor.surfaceFallback
        case .dark:
            return HiveColor.darkElevatedSurface
        }
    }

    private var border: Color {
        switch style {
        case .photo:
            return Color.white.opacity(0.08)
        case .warm:
            return HiveColor.borderFallback
        case .dark:
            return Color.white.opacity(0.08)
        }
    }

    private var primaryForeground: Color {
        style == .warm ? HiveColor.textPrimaryFallback : HiveColor.primaryLightText
    }

    private var secondaryForeground: Color {
        style == .warm ? HiveColor.textSecondaryFallback : HiveColor.secondaryLightText
    }

    private var iconForeground: Color {
        style == .photo ? HiveColor.deepEspresso : tint
    }
}

struct HiveMetricSparkline: View {
    let values: [Double]
    var tint: Color = HiveColor.livingAccent

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(tint.opacity(0.35 + min(max(value, 0), 1) * 0.55))
                    .frame(width: 5, height: max(8, 36 * min(max(value, 0), 1)))
            }
        }
        .frame(height: 40, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

struct HiveActivityRow: View {
    let actorName: String
    let message: String
    let timestamp: Date
    var tint: Color = HiveColor.premiumAccent
    var style: HiveAvatar.AvatarStyle = .warm

    var body: some View {
        HStack(alignment: .top, spacing: HiveSpacing.md) {
            HiveAvatar(name: actorName, size: 34, style: style)

            VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                Text(message)
                    .font(HiveFont.bodyMedium)
                    .foregroundStyle(style == .dark ? HiveColor.primaryLightText : HiveColor.textPrimaryFallback)
                    .fixedSize(horizontal: false, vertical: true)

                Text(timestamp.formatted(.relative(presentation: .named)))
                    .font(HiveFont.smallDetail)
                    .foregroundStyle(style == .dark ? HiveColor.secondaryLightText : HiveColor.textSecondaryFallback)
            }

            Spacer()

            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .padding(.top, 6)
        }
        .padding(.vertical, HiveSpacing.sm)
    }
}

// MARK: - Previews

#Preview("Components") {
    HiveScreen {
        ScrollView {
            VStack(alignment: .leading, spacing: HiveSpacing.xxl) {
                HivePageHeader(
                    eyebrow: "Good morning, Alex",
                    title: "The Lofts"
                ) {
                    ColonySwitcherButton()
                }

                HiveCard {
                    HiveHealthIndicator(
                        score: 76,
                        grade: "Active",
                        summary: "A great week — keep it up."
                    )
                }

                VStack(alignment: .leading, spacing: 0) {
                    HiveSectionHeader(title: "Today", action: "See all") {}
                    HiveTaskRow(
                        title: "Take out recycling",
                        subtitle: "Due today",
                        statusColor: HiveColor.honey
                    )
                    Divider()
                    HiveTaskRow(
                        title: "Clean kitchen",
                        subtitle: "Due tomorrow"
                    )
                    Divider()
                    HiveTaskRow(
                        title: "Bathroom cleaned",
                        subtitle: "Completed",
                        isCompleted: true
                    )
                }

                HiveEmptyState(
                    title: "All caught up",
                    message: "No tasks due today.",
                    systemImage: "checkmark.seal"
                )

                HStack(spacing: HiveSpacing.md) {
                    Button("Get Started") {}
                        .buttonStyle(HivePrimaryButtonStyle())
                    Button("Learn More") {}
                        .buttonStyle(HiveGhostButtonStyle())
                }
            }
            .padding(HiveSpacing.xxl)
        }
    }
    .environmentObject(HiveSpaceStore.sample)
}
