import SwiftUI

struct MessagingView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var selectedChannelID: UUID?
    @State private var draftMessage = ""
    @State private var showingNewDM = false
    @State private var selectedDMThread: DirectMessageThread?
    @State private var dmDraft = ""

    var body: some View {
        HiveScreen {
            GeometryReader { geometry in
                let isCompact = geometry.size.width < 720
                let sidebarWidth = max(220, geometry.size.width * 0.30)

                Group {
                    if isCompact {
                        VStack(spacing: 0) {
                            compactHeader
                            compactChannelStrip
                            messageThread
                            composer
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(HiveTheme.surface.opacity(0.97))
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(HiveTheme.border, lineWidth: 1)
                        }
                    } else {
                        HStack(spacing: 14) {
                            sidebar
                                .frame(width: sidebarWidth)

                            VStack(spacing: 0) {
                                channelHeader
                                Divider()
                                    .overlay(HiveTheme.border)
                                messageThread
                                composer
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(HiveTheme.surface.opacity(0.96))
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(HiveTheme.border, lineWidth: 1)
                            }
                            .shadow(color: HiveTheme.purple.opacity(0.06), radius: 18, x: 0, y: 10)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Messages")
        .sheet(isPresented: $showingNewDM) {
            NewDMSheet()
                .environmentObject(store)
        }
        .sheet(item: $selectedDMThread) { thread in
            DMConversationSheet(thread: thread)
                .environmentObject(store)
        }
        .onAppear {
            if selectedChannelID == nil {
                selectedChannelID = store.activeChannels.first?.id
            }
        }
    }

    private var selectedChannel: MessageChannel? {
        store.activeChannels.first(where: { $0.id == selectedChannelID }) ?? store.activeChannels.first
    }

    private var selectedMessages: [HSMessage] {
        guard let selectedChannel else { return [] }
        return store.messages.filter { $0.channelID == selectedChannel.id }.sorted { $0.sentAt < $1.sentAt }
    }

    private var sidebar: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Messages")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(HiveTheme.textPrimary)

                    HStack(spacing: 10) {
                        ColonyBadge(colonyName: store.colony.name, size: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.colony.name)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(HiveTheme.textPrimary)
                            Text("Colony channels")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                    }

                    ColonySwitcherButton()
                }

                sectionLabel("Channels")

                VStack(spacing: 8) {
                    ForEach(store.activeChannels) { channel in
                        channelRow(channel)
                    }
                }

                Divider()
                    .overlay(HiveTheme.border)
                    .padding(.vertical, 4)

                HStack {
                    sectionLabel("Direct Messages")
                    Spacer()
                    Button {
                        showingNewDM = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(HiveTheme.pink)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(store.directThreads) { thread in
                        Button {
                            selectedDMThread = thread
                        } label: {
                            directThreadRow(thread)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(HiveTheme.surfaceSoft.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(HiveTheme.border, lineWidth: 1)
        }
    }

    private var channelHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedChannel?.name ?? "Channel")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                Text(selectedChannel?.topic ?? "Colony conversation")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(HiveTheme.textSecondary)
            }

            Spacer()

            if let selectedChannel {
                Text(selectedChannel.kind.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(HiveTheme.surfaceSoft)
                    .foregroundStyle(HiveTheme.textSecondary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }

    private var compactHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Messages")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(HiveTheme.textPrimary)

                    if let selectedChannel {
                        Text(selectedChannel.topic ?? "Colony conversation")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(HiveTheme.textSecondary)
                    }
                }

                Spacer()

                ColonySwitcherButton()
                    .fixedSize()
            }

            HStack(spacing: 10) {
                ColonyBadge(colonyName: store.colony.name, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.colony.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(HiveTheme.textPrimary)
                    Text("Colony channels")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var compactChannelStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.activeChannels) { channel in
                    compactChannelChip(channel)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
    }

    private var messageThread: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(selectedMessages) { message in
                    let isCurrentUser = message.senderID == store.currentUser.id

                    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            if !isCurrentUser {
                                Circle()
                                    .fill(HiveTheme.surfaceSoft)
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        Text(String(message.senderName.prefix(1)).uppercased())
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(HiveTheme.pink)
                                    }
                            }

                            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 3) {
                                Text(message.senderName)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                                Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary.opacity(0.75))
                            }
                            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
                        }

                        Text(message.body)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .background(isCurrentUser ? HiveTheme.accentGradient : LinearGradient(colors: [HiveTheme.surfaceSoft, HiveTheme.surface], startPoint: .top, endPoint: .bottom))
                            .foregroundStyle(isCurrentUser ? .white : HiveTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(alignment: isCurrentUser ? .bottomTrailing : .bottomLeading) {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(isCurrentUser ? Color.white.opacity(0.12) : HiveTheme.border, lineWidth: 1)
                            }
                            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
                            .contextMenu {
                                Button("React 👍") { store.react(to: message, emoji: "👍") }
                                Button("React 👀") { store.react(to: message, emoji: "👀") }
                            }

                        if !message.reactions.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(message.reactions) { reaction in
                                    HStack(spacing: 4) {
                                        Text(reaction.emoji)
                                        Text("1")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(HiveTheme.surfaceSoft)
                                    .foregroundStyle(HiveTheme.textPrimary)
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(HiveTheme.border, lineWidth: 1)
                                    }
                                    .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.38), HiveTheme.background.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var composer: some View {
        HStack(spacing: 12) {
            Button {
            } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HiveTheme.pink)
                    .frame(width: 42, height: 42)
                    .background(HiveTheme.surfaceSoft)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(HiveTheme.border, lineWidth: 1)
                    }
            }

            TextField("Message your colony...", text: $draftMessage, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(HiveTheme.surfaceSoft)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(HiveTheme.border, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button("Send") {
                guard let selectedChannel else { return }
                store.sendMessage(draftMessage, in: selectedChannel)
                draftMessage = ""
            }
            .buttonStyle(HivePrimaryButtonStyle())
            .opacity(draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            .disabled(draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(HiveTheme.surface.opacity(0.94))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(HiveTheme.textSecondary)
    }

    private func channelRow(_ channel: MessageChannel) -> some View {
        let isSelected = selectedChannelID == channel.id
        let channelTitle = "# \(channel.name)"

        return Button {
            selectedChannelID = channel.id
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(isSelected ? HiveTheme.pink.opacity(0.18) : Color.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: channelIcon(for: channel.kind))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isSelected ? HiveTheme.pink : HiveTheme.textSecondary)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(channelTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(HiveTheme.textPrimary)
                    Text(channel.kind.rawValue)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                }

                Spacer()

                if channel.unreadCount > 0 {
                    Text("\(channel.unreadCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(HiveTheme.magenta.opacity(0.16))
                        .foregroundStyle(HiveTheme.magenta)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(isSelected ? Color.white.opacity(0.72) : Color.clear)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isSelected ? HiveTheme.pink.opacity(0.16) : Color.clear, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func directThreadRow(_ thread: DirectMessageThread) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(thread.participantIDs.filter { $0 != store.currentUser.id }.map(store.memberName).joined(separator: ", "))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(HiveTheme.textPrimary)
            Text(thread.lastMessagePreview)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(HiveTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func compactChannelChip(_ channel: MessageChannel) -> some View {
        let isSelected = selectedChannelID == channel.id

        return Button {
            selectedChannelID = channel.id
        } label: {
            HStack(spacing: 8) {
                Image(systemName: channelIcon(for: channel.kind))
                    .font(.system(size: 11, weight: .bold))
                Text("#\(channel.name)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                if channel.unreadCount > 0 {
                    Text("\(channel.unreadCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isSelected ? Color.white.opacity(0.22) : HiveTheme.magenta.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? AnyShapeStyle(HiveTheme.accentGradient) : AnyShapeStyle(HiveTheme.surfaceSoft))
            .foregroundStyle(isSelected ? .white : HiveTheme.textPrimary)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? Color.white.opacity(0.12) : HiveTheme.border, lineWidth: 1)
            }
        }
    }

    private func channelIcon(for kind: MessageChannelKind) -> String {
        switch kind {
        case .general:
            return "number"
        case .tasks:
            return "checklist"
        case .expenses:
            return "creditcard"
        case .social:
            return "bubble.left"
        case .direct:
            return "person"
        }
    }
}

// MARK: - DM Conversation Sheet

struct DMConversationSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    let thread: DirectMessageThread
    @State private var draft = ""

    private var otherUserID: UUID? {
        thread.participantIDs.first(where: { $0 != store.currentUser.id })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        HiveCard {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(HiveTheme.surfaceSoft)
                                    .frame(width: 48, height: 48)
                                    .overlay {
                                        Text(String(store.memberName(for: otherUserID ?? UUID()).prefix(1)).uppercased())
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(HiveTheme.pink)
                                    }
                                Text(store.memberName(for: otherUserID ?? UUID()))
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Text("Direct message")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        HiveCard {
                            Text(thread.lastMessagePreview)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textPrimary)
                            Text(thread.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                    }
                    .padding(18)
                }

                HStack(spacing: 12) {
                    TextField("Message...", text: $draft, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(HiveTheme.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Button("Send") {
                        guard let userID = otherUserID else { return }
                        store.sendDirectMessage(draft, to: userID)
                        draft = ""
                        dismiss()
                    }
                    .buttonStyle(HivePrimaryButtonStyle())
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(HiveTheme.surface.opacity(0.94))
            }
            .navigationTitle(store.memberName(for: otherUserID ?? UUID()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - New DM Sheet

struct NewDMSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var selectedUserID: UUID?

    var body: some View {
        NavigationStack {
            List {
                Section("Send to") {
                    ForEach(store.colony.members.filter({ $0.id != store.currentUser.id })) { member in
                        Button {
                            selectedUserID = member.id
                        } label: {
                            HStack {
                                Circle()
                                    .fill(HiveTheme.surfaceSoft)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        Text(String(member.displayName.prefix(1)).uppercased())
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(HiveTheme.pink)
                                    }
                                Text(member.displayName)
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Spacer()
                                if selectedUserID == member.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HiveTheme.pink)
                                }
                            }
                        }
                    }
                }

                if selectedUserID != nil {
                    Section("Message") {
                        TextField("Type a message...", text: $draft, axis: .vertical)
                            .lineLimit(2...5)
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        guard let userID = selectedUserID else { return }
                        store.sendDirectMessage(draft, to: userID)
                        dismiss()
                    }
                    .disabled(selectedUserID == nil || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessagingView()
            .environmentObject(HiveSpaceStore.sample)
    }
}
