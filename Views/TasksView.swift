import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var selectedStatus: TaskStatus? = nil
    @State private var showingAddTask = false
    @State private var selectedTask: HSTask?

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HivePageHeader(
                        eyebrow: store.colony.name,
                        title: "Tasks",
                        subtitle: "Assignments, nudges, and due dates"
                    ) {
                        HStack(spacing: 10) {
                            Button {
                                showingAddTask = true
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(HiveTheme.pink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            ColonySwitcherButton()
                        }
                    }

                    statusFilter

                    if !store.choreWheels.isEmpty {
                        choreWheelSection
                    }

                    if filteredTasks.isEmpty {
                        HiveEmptyState(
                            title: "No tasks",
                            message: selectedStatus == nil ? "Create a task to get started." : "No tasks match this filter.",
                            systemImage: "checklist"
                        )
                    } else {
                        ForEach(filteredTasks) { task in
                            Button {
                                selectedTask = task
                            } label: {
                                taskCard(task)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Tasks")
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet()
                .environmentObject(store)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task)
                .environmentObject(store)
        }
    }

    private var filteredTasks: [HSTask] {
        let colonyTasks = store.tasks.filter { $0.colonyID == store.colony.id }
        if let selectedStatus {
            return colonyTasks.filter { $0.status == selectedStatus }
        }
        return colonyTasks
    }

    private var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    filterChip(status.rawValue, isSelected: selectedStatus == status) {
                        selectedStatus = status
                    }
                }
            }
        }
    }

    private var choreWheelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HiveSectionTitle(title: "Chore Wheel")

            ForEach(store.choreWheels) { chore in
                HiveCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(chore.choreName)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(HiveTheme.textPrimary)
                            Text("Current: \(store.memberName(for: chore.currentAssigneeID))")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                            Text("Rotates \(chore.rotationFrequency.rawValue.lowercased()) • Next: \(chore.nextRotationAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                        Spacer()
                        Button("Rotate") {
                            withAnimation(.spring(response: 0.3)) {
                                store.rotateChore(chore)
                            }
                        }
                        .buttonStyle(HivePrimaryButtonStyle())
                    }
                }
            }
        }
    }

    private func taskCard(_ task: HSTask) -> some View {
        HiveCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            HiveStatusDot(color: statusColor(task))
                            Text(statusTitle(task))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(statusColor(task))
                        }

                        Text(task.title)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                        if let desc = task.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(HiveTheme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            store.toggleTaskCompletion(task)
                        }
                    } label: {
                        Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    .foregroundStyle(task.status == .done ? HiveTheme.green : HiveTheme.textSecondary)
                }

                HStack(spacing: 8) {
                    chip(task.priority.rawValue, color: priorityColor(task.priority))

                    if !task.tags.isEmpty {
                        chip(task.tags.first ?? "", color: HiveTheme.purple)
                    }

                    Spacer()

                    if let dueDate = task.dueDate {
                        let isOverdue = dueDate < Date() && task.status != .done
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(isOverdue ? HiveTheme.red : HiveTheme.textSecondary)
                    }
                }

                HStack {
                    HStack(spacing: -6) {
                        ForEach(task.assignedToIDs.prefix(3), id: \.self) { memberID in
                            Circle()
                                .fill(HiveTheme.surfaceSoft)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Text(String(store.memberName(for: memberID).prefix(1)))
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(HiveTheme.pink)
                                }
                                .overlay {
                                    Circle().strokeBorder(Color.white, lineWidth: 1.5)
                                }
                        }
                    }

                    Text(task.assignedToIDs.map(store.memberName).joined(separator: ", "))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    if task.status != .done {
                        Button("Nudge") {
                            store.sendNudge(for: task)
                        }
                        .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.pink))
                    }
                }
            }
        }
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? AnyShapeStyle(HiveTheme.accentGradient) : AnyShapeStyle(HiveTheme.surface))
                .foregroundStyle(isSelected ? .white : HiveTheme.textPrimary)
                .clipShape(Capsule())
                .overlay {
                    Capsule().strokeBorder(isSelected ? Color.clear : HiveTheme.border, lineWidth: 1)
                }
        }
    }

    private func chip(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func statusColor(_ task: HSTask) -> Color {
        if task.status == .todo, let due = task.dueDate, due < Date() {
            return HiveTheme.red
        }
        switch task.status {
        case .todo: return HiveTheme.yellow
        case .inProgress: return HiveTheme.yellow
        case .done: return HiveTheme.green
        }
    }

    private func statusTitle(_ task: HSTask) -> String {
        if task.status == .todo, let due = task.dueDate, due < Date() {
            return "OVERDUE"
        }
        switch task.status {
        case .todo: return "TO DO"
        case .inProgress: return "IN PROGRESS"
        case .done: return "DONE"
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return HiveTheme.green
        case .medium: return HiveTheme.yellow
        case .high: return HiveTheme.pink
        }
    }
}

// MARK: - Add Task Sheet

struct AddTaskSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(60 * 60 * 24)
    @State private var selectedMemberIDs: Set<UUID> = []
    @State private var tagText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Task title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate)
                    }
                }

                Section("Assign To") {
                    ForEach(store.colony.members) { member in
                        Button {
                            if selectedMemberIDs.contains(member.id) {
                                selectedMemberIDs.remove(member.id)
                            } else {
                                selectedMemberIDs.insert(member.id)
                            }
                        } label: {
                            HStack {
                                Text(member.displayName)
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Spacer()
                                if selectedMemberIDs.contains(member.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HiveTheme.pink)
                                }
                            }
                        }
                    }
                }

                Section("Tag") {
                    TextField("Tag (e.g. Cleaning)", text: $tagText)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let tags = tagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [tagText.trimmingCharacters(in: .whitespacesAndNewlines)]
                        store.addTask(
                            title: title,
                            description: description.isEmpty ? nil : description,
                            priority: priority,
                            assignedToIDs: Array(selectedMemberIDs),
                            dueDate: hasDueDate ? dueDate : nil,
                            tags: tags
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Task Detail Sheet

struct TaskDetailSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    let task: HSTask
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priority: TaskPriority = .medium
    @State private var status: TaskStatus = .todo
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedMemberIDs: Set<UUID> = []
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Info") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Due Date") {
                    Toggle("Has due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate)
                    }
                }

                Section("Assigned To") {
                    ForEach(store.colony.members) { member in
                        Button {
                            if selectedMemberIDs.contains(member.id) {
                                selectedMemberIDs.remove(member.id)
                            } else {
                                selectedMemberIDs.insert(member.id)
                            }
                        } label: {
                            HStack {
                                Text(member.displayName)
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Spacer()
                                if selectedMemberIDs.contains(member.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HiveTheme.pink)
                                }
                            }
                        }
                    }
                }

                if task.completedAt != nil {
                    Section("Completed") {
                        if let completedAt = task.completedAt {
                            Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                        if let completedByID = task.completedByID {
                            Text("By \(store.memberName(for: completedByID))")
                                .foregroundStyle(HiveTheme.textSecondary)
                        }
                    }
                }

                Section {
                    Button("Delete Task", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateTask(
                            task,
                            title: title,
                            description: description.isEmpty ? nil : description,
                            priority: priority,
                            status: status,
                            assignedToIDs: Array(selectedMemberIDs),
                            dueDate: hasDueDate ? dueDate : nil
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    store.deleteTask(task)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \"\(task.title)\"? This cannot be undone.")
            }
            .onAppear {
                title = task.title
                description = task.description ?? ""
                priority = task.priority
                status = task.status
                hasDueDate = task.dueDate != nil
                dueDate = task.dueDate ?? Date()
                selectedMemberIDs = Set(task.assignedToIDs)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TasksView()
            .environmentObject(HiveSpaceStore.sample)
    }
}
