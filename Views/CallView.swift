import SwiftUI

struct CallView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var showingScheduler = false
    @State private var scheduledDate = Date().addingTimeInterval(60 * 60 * 24)
    @State private var scheduledTitle = "Colony Sync"
    @State private var scheduledType: CallType = .video

    private var scheduledCalls: [CallSession] {
        store.callSessions
            .filter { $0.state == .scheduled && $0.colonyID == store.colony.id }
            .sorted { ($0.scheduledFor ?? .distantFuture) < ($1.scheduledFor ?? .distantFuture) }
    }

    private var endedCalls: [CallSession] {
        store.callSessions
            .filter { $0.state == .ended && $0.colonyID == store.colony.id }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
    }

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: HiveSpacing.xl) {
                    HivePageHeader(
                        eyebrow: "Colony",
                        title: "Calls",
                        subtitle: "Voice and video rooms for quick house syncs"
                    ) {
                        ColonySwitcherButton()
                    }

                    CallQuickActions(
                        onStartVoice: { store.startCall(type: .voice) },
                        onStartVideo: { store.startCall(type: .video) },
                        onSchedule: { showingScheduler = true }
                    )

                    if let call = store.activeCallSession {
                        CurrentCallCard(
                            call: call,
                            participants: store.currentCallParticipants,
                            currentUserParticipant: store.callParticipants.first(where: { $0.id == store.currentUser.id }),
                            onJoin: { store.joinCall(call) },
                            onDecline: { store.endCall(call) },
                            onEnd: { store.endCall(call) },
                            onToggleMute: { store.toggleCurrentUserMute() },
                            onToggleCamera: { store.toggleCurrentUserCamera() },
                            onToggleSpeaking: { store.toggleCurrentUserSpeaking() }
                        )
                    } else {
                        HiveEmptyState(
                            title: "No calls in motion",
                            message: "Start a room when a thread needs voices, or schedule the next colony sync.",
                            systemImage: "phone.badge.plus"
                        )
                    }

                    if !scheduledCalls.isEmpty {
                        CallListSection(title: "Upcoming", calls: scheduledCalls) { call in
                            store.joinCall(call)
                        }
                    }

                    if !endedCalls.isEmpty {
                        RecentCallSection(calls: Array(endedCalls.prefix(5)))
                    }
                }
                .padding(HiveSpacing.xxl)
            }
        }
        .navigationTitle("Calls")
        .sheet(isPresented: $showingScheduler) {
            ScheduleCallSheet(
                title: $scheduledTitle,
                date: $scheduledDate,
                type: $scheduledType,
                onSave: {
                    store.scheduleCall(title: scheduledTitle, type: scheduledType, date: scheduledDate)
                    showingScheduler = false
                }
            )
        }
    }
}

private struct CallQuickActions: View {
    let onStartVoice: () -> Void
    let onStartVideo: () -> Void
    let onSchedule: () -> Void

    var body: some View {
        HiveCard {
            VStack(alignment: .leading, spacing: HiveSpacing.md) {
                HStack(spacing: HiveSpacing.md) {
                    CallActionButton(title: "Voice", systemImage: "phone.fill", action: onStartVoice)
                    CallActionButton(title: "Video", systemImage: "video.fill", action: onStartVideo)
                    CallActionButton(title: "Later", systemImage: "calendar.badge.plus", action: onSchedule)
                }
            }
        }
    }
}

private struct CallActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: HiveSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .background(HiveColor.brandSubtleFallback)
                    .clipShape(RoundedRectangle(cornerRadius: HiveRadius.md, style: .continuous))
                Text(title)
                    .font(HiveFont.captionMedium)
            }
            .foregroundStyle(HiveColor.textPrimaryFallback)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct CurrentCallCard: View {
    let call: CallSession
    let participants: [CallParticipantState]
    let currentUserParticipant: CallParticipantState?
    let onJoin: () -> Void
    let onDecline: () -> Void
    let onEnd: () -> Void
    let onToggleMute: () -> Void
    let onToggleCamera: () -> Void
    let onToggleSpeaking: () -> Void

    private var isActive: Bool { call.state == .active }
    private var isIncoming: Bool { call.state == .incoming }
    private var statusText: String {
        if isActive, let startedAt = call.startedAt {
            return "Started \(startedAt.formatted(date: .omitted, time: .shortened))"
        }
        if call.state == .scheduled, let scheduledFor = call.scheduledFor {
            return scheduledFor.formatted(date: .abbreviated, time: .shortened)
        }
        return call.state.rawValue
    }

    var body: some View {
        HiveCard {
            VStack(alignment: .leading, spacing: HiveSpacing.lg) {
                CurrentCallHeader(
                    title: call.title,
                    type: call.type,
                    status: statusText,
                    state: call.state,
                    onJoin: onJoin,
                    onDecline: onDecline,
                    onEnd: onEnd
                )

                ParticipantGrid(participants: participants)

                if isActive {
                    CallControlBar(
                        callType: call.type,
                        participant: currentUserParticipant,
                        onToggleMute: onToggleMute,
                        onToggleCamera: onToggleCamera,
                        onToggleSpeaking: onToggleSpeaking,
                        onEnd: onEnd
                    )
                } else if isIncoming {
                    Text("Incoming colony call")
                        .font(HiveFont.captionMedium)
                        .foregroundStyle(HiveColor.brandFallback)
                }
            }
        }
    }
}

private struct CurrentCallHeader: View {
    let title: String
    let type: CallType
    let status: String
    let state: CallState
    let onJoin: () -> Void
    let onDecline: () -> Void
    let onEnd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: HiveSpacing.md) {
            Image(systemName: type == .video ? "video.fill" : "phone.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HiveColor.brandFallback)
                .frame(width: 42, height: 42)
                .background(HiveColor.brandSubtleFallback)
                .clipShape(RoundedRectangle(cornerRadius: HiveRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                Text(title)
                    .font(HiveFont.sectionTitle)
                    .foregroundStyle(HiveColor.textPrimaryFallback)
                Text(status)
                    .font(HiveFont.caption)
                    .foregroundStyle(HiveColor.textSecondaryFallback)
            }

            Spacer()

            switch state {
            case .incoming:
                HStack(spacing: HiveSpacing.sm) {
                    Button("Decline", action: onDecline)
                        .buttonStyle(HiveGhostButtonStyle(color: HiveColor.destructive))
                    Button("Accept", action: onJoin)
                        .buttonStyle(HivePrimaryButtonStyle())
                }
            case .scheduled:
                Button("Join", action: onJoin)
                    .buttonStyle(HivePrimaryButtonStyle())
            case .active:
                Button("End", action: onEnd)
                    .buttonStyle(HiveGhostButtonStyle(color: HiveColor.destructive))
            case .idle, .ended:
                EmptyView()
            }
        }
    }
}

private struct ParticipantGrid: View {
    let participants: [CallParticipantState]

    private let columns = [
        GridItem(.adaptive(minimum: 132), spacing: HiveSpacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: HiveSpacing.md) {
            ForEach(participants) { participant in
                ParticipantTile(participant: participant)
            }
        }
    }
}

private struct ParticipantTile: View {
    let participant: CallParticipantState

    var body: some View {
        VStack(spacing: HiveSpacing.md) {
            Circle()
                .fill(participant.isSpeaking ? HiveColor.brandSubtleFallback : HiveColor.surfaceElevatedFallback)
                .frame(width: 72, height: 72)
                .overlay {
                    Text(String(participant.displayName.prefix(1)))
                        .font(HiveFont.body(26, weight: .semibold))
                        .foregroundStyle(participant.isSpeaking ? HiveColor.brandFallback : HiveColor.textPrimaryFallback)
                }
                .overlay {
                    if participant.isSpeaking {
                        Circle()
                            .strokeBorder(HiveColor.brandFallback, lineWidth: 2)
                    }
                }

            VStack(spacing: HiveSpacing.xs) {
                Text(participant.displayName)
                    .font(HiveFont.captionMedium)
                    .foregroundStyle(HiveColor.textPrimaryFallback)
                    .lineLimit(1)

                HStack(spacing: HiveSpacing.sm) {
                    Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                    Image(systemName: participant.isCameraOn ? "video.fill" : "video.slash.fill")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HiveColor.textSecondaryFallback)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 154)
        .padding(HiveSpacing.md)
        .background(HiveColor.surfaceElevatedFallback)
        .clipShape(RoundedRectangle(cornerRadius: HiveRadius.card, style: .continuous))
    }
}

private struct CallControlBar: View {
    let callType: CallType
    let participant: CallParticipantState?
    let onToggleMute: () -> Void
    let onToggleCamera: () -> Void
    let onToggleSpeaking: () -> Void
    let onEnd: () -> Void

    var body: some View {
        HStack(spacing: HiveSpacing.md) {
            CallControlButton(
                systemImage: participant?.isMuted == true ? "mic.slash.fill" : "mic.fill",
                title: participant?.isMuted == true ? "Muted" : "Mic",
                isSelected: participant?.isMuted == false,
                action: onToggleMute
            )

            if callType == .video {
                CallControlButton(
                    systemImage: participant?.isCameraOn == true ? "video.fill" : "video.slash.fill",
                    title: participant?.isCameraOn == true ? "Camera" : "Off",
                    isSelected: participant?.isCameraOn == true,
                    action: onToggleCamera
                )
            }

            CallControlButton(
                systemImage: participant?.isSpeaking == true ? "waveform.circle.fill" : "waveform.circle",
                title: participant?.isSpeaking == true ? "Live" : "Talk",
                isSelected: participant?.isSpeaking == true,
                action: onToggleSpeaking
            )

            Spacer()

            Button(action: onEnd) {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(HiveColor.destructive)
                    .clipShape(Circle())
            }
            .accessibilityLabel("End call")
        }
    }
}

private struct CallControlButton: View {
    let systemImage: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: HiveSpacing.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(HiveFont.label)
            }
            .foregroundStyle(isSelected ? HiveColor.textPrimaryFallback : HiveColor.textSecondaryFallback)
            .frame(width: 58, height: 52)
            .background(isSelected ? HiveColor.brandSubtleFallback : HiveColor.surfaceElevatedFallback)
            .clipShape(RoundedRectangle(cornerRadius: HiveRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CallListSection: View {
    let title: String
    let calls: [CallSession]
    let onJoin: (CallSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.md) {
            HiveSectionTitle(title: title)
            ForEach(calls) { call in
                ScheduledCallRow(call: call, onJoin: { onJoin(call) })
            }
        }
    }
}

private struct ScheduledCallRow: View {
    let call: CallSession
    let onJoin: () -> Void

    var body: some View {
        HiveCard {
            HStack(spacing: HiveSpacing.md) {
                Image(systemName: call.type == .video ? "video.fill" : "phone.fill")
                    .foregroundStyle(HiveColor.brandFallback)
                    .frame(width: 36, height: 36)
                    .background(HiveColor.brandSubtleFallback)
                    .clipShape(RoundedRectangle(cornerRadius: HiveRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                    Text(call.title)
                        .font(HiveFont.bodyMedium)
                        .foregroundStyle(HiveColor.textPrimaryFallback)
                    Text(call.scheduledFor?.formatted(date: .abbreviated, time: .shortened) ?? "Time TBD")
                        .font(HiveFont.caption)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                    Text("\(call.participantIDs.count) participants")
                        .font(HiveFont.smallDetail)
                        .foregroundStyle(HiveColor.textSecondaryFallback)
                }

                Spacer()

                Button("Join", action: onJoin)
                    .buttonStyle(HivePrimaryButtonStyle())
            }
        }
    }
}

private struct RecentCallSection: View {
    let calls: [CallSession]

    var body: some View {
        VStack(alignment: .leading, spacing: HiveSpacing.md) {
            HiveSectionTitle(title: "Recent Calls")
            ForEach(calls) { call in
                RecentCallRow(call: call)
            }
        }
    }
}

private struct RecentCallRow: View {
    let call: CallSession

    var body: some View {
        HStack(spacing: HiveSpacing.md) {
            Image(systemName: call.type == .video ? "video.fill" : "phone.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HiveColor.textSecondaryFallback)
                .frame(width: 32, height: 32)
                .background(HiveColor.surfaceElevatedFallback)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: HiveSpacing.xs) {
                Text(call.title)
                    .font(HiveFont.bodyMedium)
                    .foregroundStyle(HiveColor.textPrimaryFallback)
                Text(call.startedAt?.formatted(date: .abbreviated, time: .shortened) ?? "No start time")
                    .font(HiveFont.caption)
                    .foregroundStyle(HiveColor.textSecondaryFallback)
            }

            Spacer()
        }
        .padding(.vertical, HiveSpacing.xs)
    }
}

private struct ScheduleCallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var title: String
    @Binding var date: Date
    @Binding var type: CallType
    let onSave: () -> Void

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Call title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(CallType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type == .video ? "video.fill" : "phone.fill")
                                .tag(type)
                        }
                    }
                    DatePicker("Schedule", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Schedule Call")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(!canSave)
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
