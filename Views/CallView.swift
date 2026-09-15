import SwiftUI

struct CallView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var showingScheduler = false
    @State private var scheduledDate = Date().addingTimeInterval(60 * 60 * 24)
    @State private var scheduledTitle = "Colony Sync"
    @State private var scheduledType: CallType = .video

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HivePageHeader(
                        eyebrow: "Colony",
                        title: "Calls",
                        subtitle: "Voice and video sessions for your current colony"
                    ) {
                        ColonySwitcherButton()
                    }

                    if let call = store.activeCallSession {
                        activeCallSection(call)
                    } else {
                        HiveEmptyState(
                            title: "No active calls",
                            message: "Schedule a sync or wait for an incoming colony call.",
                            systemImage: "video.slash.fill"
                        )
                    }

                    Button("Schedule Call") {
                        showingScheduler = true
                    }
                    .buttonStyle(HivePrimaryButtonStyle())

                    let scheduledCalls = store.callSessions.filter { $0.state == .scheduled && $0.colonyID == store.colony.id }
                    if !scheduledCalls.isEmpty {
                        HiveSectionTitle(title: "Scheduled")
                        ForEach(scheduledCalls) { call in
                            scheduledCallCard(call)
                        }
                    }

                    allCallsSection
                }
                .padding(24)
            }
        }
        .navigationTitle("Calls")
        .sheet(isPresented: $showingScheduler) {
            NavigationStack {
                Form {
                    TextField("Call title", text: $scheduledTitle)
                    Picker("Type", selection: $scheduledType) {
                        ForEach(CallType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    DatePicker("Schedule", selection: $scheduledDate)
                }
                .navigationTitle("Schedule Call")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            store.scheduleCall(title: scheduledTitle, type: scheduledType, date: scheduledDate)
                            showingScheduler = false
                        }
                    }
                }
            }
        }
    }

    private func activeCallSection(_ call: CallSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(call.title)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(HiveTheme.textPrimary)
                    Text(call.state.rawValue)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                }
                Spacer()
                if call.state == .incoming {
                    HStack(spacing: 10) {
                        Button("Decline") { store.endCall(call) }
                            .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.red))
                        Button("Accept") { store.joinCall(call) }
                            .buttonStyle(HivePrimaryButtonStyle())
                    }
                } else if call.state == .active {
                    Button("End Call") { store.endCall(call) }
                        .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.red))
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(store.callParticipants) { participant in
                    VStack(spacing: 12) {
                        Circle()
                            .fill((participant.isSpeaking ? HiveTheme.pink : HiveTheme.surfaceSoft).opacity(0.9))
                            .frame(height: 88)
                            .overlay {
                                Text(String(participant.displayName.prefix(1)))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(HiveTheme.textPrimary)
                            }

                        Text(participant.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)

                        HStack(spacing: 8) {
                            Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                            Image(systemName: participant.isCameraOn ? "video.fill" : "video.slash.fill")
                        }
                        .foregroundStyle(HiveTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(HiveTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
        }
    }

    private func scheduledCallCard(_ call: CallSession) -> some View {
        HiveCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: call.type == .video ? "video.fill" : "phone.fill")
                            .foregroundStyle(HiveTheme.purple)
                        Text(call.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)
                    }
                    Text(call.scheduledFor?.formatted(date: .abbreviated, time: .shortened) ?? "TBD")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                    Text("\(call.participantIDs.count) participants")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                }
                Spacer()
                Button("Join") {
                    store.joinCall(call)
                }
                .buttonStyle(HivePrimaryButtonStyle())
            }
        }
    }

    private var allCallsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let endedCalls = store.callSessions.filter { $0.state == .ended && $0.colonyID == store.colony.id }
            if !endedCalls.isEmpty {
                HiveSectionTitle(title: "Recent Calls")
                ForEach(endedCalls.prefix(5)) { call in
                    HiveCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(call.title)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Text(call.startedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: call.type == .video ? "video.fill" : "phone.fill")
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CallView()
            .environmentObject(HiveSpaceStore.sample)
    }
}
