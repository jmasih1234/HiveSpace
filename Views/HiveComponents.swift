import SwiftUI

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
