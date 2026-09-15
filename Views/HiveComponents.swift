import SwiftUI

struct HiveLogoMark: View {
    var size: CGFloat = 32
    var shadowOpacity: Double = 0.12

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.88, green: 0.80, blue: 0.90).opacity(0.8))
                .frame(width: size * 0.78, height: size * 0.14)
                .offset(y: size * 0.34)

            VStack(spacing: -size * 0.055) {
                hiveCell(
                    size: size * 0.24,
                    topColor: Color(red: 0.98, green: 0.47, blue: 0.68),
                    bottomColor: Color(red: 0.90, green: 0.20, blue: 0.51)
                )

                HStack(spacing: -size * 0.04) {
                    hiveCell(
                        size: size * 0.24,
                        topColor: Color(red: 0.84, green: 0.54, blue: 0.90),
                        bottomColor: Color(red: 0.63, green: 0.23, blue: 0.77)
                    )
                    hiveCell(
                        size: size * 0.24,
                        topColor: Color(red: 0.84, green: 0.54, blue: 0.90),
                        bottomColor: Color(red: 0.63, green: 0.23, blue: 0.77)
                    )
                }

                HStack(spacing: -size * 0.04) {
                    hiveCell(
                        size: size * 0.24,
                        topColor: Color(red: 0.71, green: 0.53, blue: 0.95),
                        bottomColor: Color(red: 0.42, green: 0.20, blue: 0.83)
                    )
                    hiveCell(
                        size: size * 0.24,
                        topColor: Color(red: 0.71, green: 0.53, blue: 0.95),
                        bottomColor: Color(red: 0.42, green: 0.20, blue: 0.83)
                    )
                    hiveCell(
                        size: size * 0.24,
                        topColor: Color(red: 0.71, green: 0.53, blue: 0.95),
                        bottomColor: Color(red: 0.42, green: 0.20, blue: 0.83)
                    )
                }
            }
            .compositingGroup()
            .shadow(color: HiveTheme.purple.opacity(shadowOpacity), radius: size * 0.08, x: 0, y: size * 0.05)
        }
        .frame(width: size, height: size)
    }

    private func hiveCell(size: CGFloat, topColor: Color, bottomColor: Color) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(topColor)
                .frame(height: size * 0.54)
            Rectangle()
                .fill(bottomColor)
                .frame(height: size * 0.46)
        }
        .frame(width: size, height: size * 0.92)
        .clipShape(HiveHexCell())
        .overlay {
            HiveHexCell()
                .stroke(Color.white.opacity(0.5), lineWidth: max(0.8, size * 0.018))
        }
    }
}

private struct HiveHexCell: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.18
        let midX = rect.midX

        var path = Path()
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - rect.height * 0.25))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + rect.height * 0.25))
        path.closeSubpath()
        return path
    }
}

struct HivePageHeader<Trailing: View>: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: Trailing

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top) {
            HStack(alignment: .top, spacing: 12) {
                HiveLogoMark(size: 34, shadowOpacity: 0.08)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    if let eyebrow {
                        Text(eyebrow.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(HiveTheme.textSecondary)
                    }

                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(HiveTheme.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(HiveTheme.textSecondary)
                    }
                }
            }

            Spacer()
            trailing
        }
    }
}

struct ColonySwitcherButton: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var showingColonyPicker = false

    var body: some View {
        Button {
            showingColonyPicker = true
        } label: {
            HStack(spacing: 8) {
                ColonyBadge(colonyName: store.colony.name, size: 26)
                Text(store.colony.name)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(HiveTheme.surface)
            .foregroundStyle(HiveTheme.textPrimary)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(HiveTheme.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                                ColonyBadge(colonyName: colony.name, size: 34)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(colony.name)
                                    Text(colony.type.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if colony.id == store.colony.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HiveTheme.pink)
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

struct ColonyBadge: View {
    let colonyName: String
    var size: CGFloat = 32

    var body: some View {
        HiveLogoMark(size: size, shadowOpacity: 0.08)
            .accessibilityLabel("\(colonyName) logo")
    }
}

struct HiveEmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HiveCard {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(HiveTheme.pink)
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                Text(message)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(HiveTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
#Preview {
    HiveScreen {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HivePageHeader(
                    eyebrow: "Preview",
                    title: "HiveSpace",
                    subtitle: "Shared app components"
                ) {
                    ColonySwitcherButton()
                }

                HiveCard {
                    HStack(spacing: 14) {
                        HiveLogoMark(size: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Component Library")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(HiveTheme.textPrimary)
                            Text("Logo, cards, headers, and colony controls.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                    }
                }

                HiveEmptyState(
                    title: "Ready to Build",
                    message: "This preview verifies the shared component layer.",
                    systemImage: "checkmark.seal.fill"
                )
            }
            .padding(24)
        }
    }
    .environmentObject(HiveSpaceStore.sample)
}

