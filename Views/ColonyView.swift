import SwiftUI

struct ColonyView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    let onSignOut: () -> Void
    @State private var showingArchiveConfirmation = false
    @State private var showingSettings = false
    @State private var showingAddChore = false

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HivePageHeader(
                        eyebrow: "Colony",
                        title: store.colony.name,
                        subtitle: "Join code: \(store.colony.joinCode)"
                    ) {
                        HStack(spacing: 10) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
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

                    // Invite Card
                    HiveCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HiveSectionTitle(title: "Invite Members")
                            Text("Share this code with friends to join your colony.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                            HStack {
                                Text(store.colony.joinCode)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Spacer()
                                Button("Copy") {
                                    UIPasteboard.general.string = store.colony.joinCode
                                }
                                .buttonStyle(HivePrimaryButtonStyle())
                            }
                        }
                    }

                    // Members
                    sectionCard(title: "Members (\(store.colony.memberCount))") {
                        ForEach(store.colony.members) { member in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(HiveTheme.surfaceSoft)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Text(String(member.displayName.prefix(1)).uppercased())
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(HiveTheme.pink)
                                    }

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(member.displayName)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundStyle(HiveTheme.textPrimary)
                                        if member.id == store.currentUser.id {
                                            Text("You")
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(HiveTheme.pink.opacity(0.12))
                                                .foregroundStyle(HiveTheme.pink)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text("\(member.username) • \(member.role.rawValue)")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(HiveTheme.textSecondary)
                                }
                                Spacer()

                                HStack(spacing: 6) {
                                    HiveStatusDot(color: member.status == .active ? HiveTheme.green : HiveTheme.yellow)
                                    Text(member.status.rawValue)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(HiveTheme.textSecondary)
                                }
                            }
                            if member.id != store.colony.members.last?.id {
                                Divider().overlay(HiveTheme.border)
                            }
                        }
                    }

                    // Join Requests
                    if !store.joinRequests.isEmpty {
                        sectionCard(title: "Join Requests") {
                            ForEach(store.joinRequests) { request in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Request from \(request.requesterID.uuidString.prefix(6))")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(HiveTheme.textPrimary)
                                        Text(request.requestedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundStyle(HiveTheme.textSecondary)
                                    }
                                    Spacer()
                                    if request.status == .pending {
                                        Button("Approve") {
                                            withAnimation(.spring(response: 0.3)) {
                                                store.approve(request)
                                            }
                                        }
                                        .buttonStyle(HivePrimaryButtonStyle())
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(HiveTheme.green)
                                            Text(request.status.rawValue)
                                                .foregroundStyle(HiveTheme.green)
                                        }
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                    }
                                }
                            }
                        }
                    }

                    // Chore Wheels
                    sectionCard(title: "Chore Wheels") {
                        if store.choreWheels.isEmpty {
                            Text("No chore wheels configured.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                        }

                        ForEach(store.choreWheels) { chore in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(chore.choreName)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(HiveTheme.textPrimary)
                                    Text("Current: \(store.memberName(for: chore.currentAssigneeID)) • \(chore.rotationFrequency.rawValue)")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(HiveTheme.textSecondary)
                                }
                                Spacer()
                                Button("Rotate") {
                                    withAnimation(.spring(response: 0.3)) {
                                        store.rotateChore(chore)
                                    }
                                }
                                .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.pink))
                            }
                        }

                        Button("Add Chore") {
                            showingAddChore = true
                        }
                        .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.purple))
                    }

                    // Semester Mode
                    sectionCard(title: "Semester Mode") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Archive the current cycle into a semester snapshot. This preserves stats and resets for a fresh start.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)

                            if !store.semesterSnapshots.isEmpty {
                                HiveSectionTitle(title: "Past Semesters")
                                ForEach(store.semesterSnapshots) { snapshot in
                                    HStack {
                                        Text(snapshot.semesterLabel)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(HiveTheme.textPrimary)
                                        Spacer()
                                        Text("Score: \(snapshot.finalHealthScore)")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(HiveTheme.textSecondary)
                                    }
                                }
                            }

                            Button("Archive Semester") {
                                showingArchiveConfirmation = true
                            }
                            .buttonStyle(HivePrimaryButtonStyle())
                        }
                    }

                    // Session
                    sectionCard(title: "Session") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Signed in as \(store.currentUser.displayName)")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                            Text(store.currentUser.shareableID)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                            Button("Sign Out") {
                                onSignOut()
                            }
                            .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.red))
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Colony")
        .alert("Archive Semester", isPresented: $showingArchiveConfirmation) {
            Button("Archive", role: .destructive) {
                store.archiveSemester()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will archive all current data into a snapshot and can't be undone. Continue?")
        }
        .sheet(isPresented: $showingSettings) {
            ColonySettingsSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAddChore) {
            AddChoreWheelSheet()
                .environmentObject(store)
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HiveCard {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(HiveTheme.textPrimary)
            content()
        }
    }
}

// MARK: - Colony Settings Sheet

struct ColonySettingsSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var isPublic: Bool = false
    @State private var allowGuestView: Bool = true
    @State private var nudgesEnabled: Bool = true
    @State private var semesterMode: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Colony Info") {
                    LabeledContent("Name", value: store.colony.name)
                    LabeledContent("Type", value: store.colony.type.rawValue)
                    LabeledContent("Join Code", value: store.colony.joinCode)
                    LabeledContent("Members", value: "\(store.colony.memberCount)")
                }
                Section("Privacy") {
                    Toggle("Public colony", isOn: $isPublic)
                    Toggle("Allow guest view", isOn: $allowGuestView)
                }
                Section("Features") {
                    Toggle("Nudges enabled", isOn: $nudgesEnabled)
                    Toggle("Semester mode", isOn: $semesterMode)
                }
            }
            .navigationTitle("Colony Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var settings = store.colony.settings
                        settings.isPublic = isPublic
                        settings.allowGuestView = allowGuestView
                        settings.nudgesEnabled = nudgesEnabled
                        settings.semesterMode = semesterMode
                        store.updateColonySettings(settings)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isPublic = store.colony.settings.isPublic
                allowGuestView = store.colony.settings.allowGuestView
                nudgesEnabled = store.colony.settings.nudgesEnabled
                semesterMode = store.colony.settings.semesterMode
            }
        }
    }
}

// MARK: - Add Chore Wheel Sheet

struct AddChoreWheelSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var frequency: RecurrenceFrequency = .weekly

    var body: some View {
        NavigationStack {
            Form {
                TextField("Chore name (e.g. Trash Night)", text: $name)
                Picker("Rotation", selection: $frequency) {
                    ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                Section("Participants") {
                    Text("All \(store.colony.members.count) colony members will be included in the rotation.")
                        .foregroundStyle(HiveTheme.textSecondary)
                }
            }
            .navigationTitle("New Chore Wheel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.addChoreWheel(name: name, frequency: frequency)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ColonyView(onSignOut: {})
            .environmentObject(HiveSpaceStore.sample)
    }
}
