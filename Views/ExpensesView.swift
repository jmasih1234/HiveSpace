import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @State private var showingAddExpense = false
    @State private var showingSettleUp = false
    @State private var selectedExpense: Expense?

    var body: some View {
        HiveScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HivePageHeader(
                        eyebrow: store.colony.name,
                        title: "Split",
                        subtitle: "Balances, expenses, and event opt-ins"
                    ) {
                        HStack(spacing: 10) {
                            Button {
                                showingAddExpense = true
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

                    balanceCard

                    HStack(spacing: 12) {
                        Button("Settle Up") {
                            showingSettleUp = true
                        }
                        .buttonStyle(HivePrimaryButtonStyle())

                        Button("Add Expense") {
                            showingAddExpense = true
                        }
                        .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.pink))
                    }

                    if !store.unsettledExpenses.isEmpty {
                        HiveSectionTitle(title: "Open Expenses")

                        ForEach(store.unsettledExpenses) { expense in
                            Button {
                                selectedExpense = expense
                            } label: {
                                expenseCard(expense)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    let settledExpenses = store.expenses.filter(\.isFullySettled)
                    if !settledExpenses.isEmpty {
                        HiveSectionTitle(title: "Settled")

                        ForEach(settledExpenses) { expense in
                            Button {
                                selectedExpense = expense
                            } label: {
                                settledExpenseCard(expense)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !store.eventSplits.isEmpty {
                        HiveSectionTitle(title: "Event Splits")

                        ForEach(store.eventSplits) { split in
                            eventSplitCard(split)
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Split")
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingSettleUp) {
            SettleUpSheet()
                .environmentObject(store)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailSheet(expense: expense)
                .environmentObject(store)
        }
    }

    private var balanceCard: some View {
        HiveCard {
            HiveSectionTitle(title: "Balances", trailing: "\(store.currency(store.outstandingBalanceTotal)) owed")

            ForEach(store.balanceSummaries) { summary in
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(HiveTheme.surfaceSoft)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Text(String(summary.displayName.prefix(2)).uppercased())
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(HiveTheme.pink)
                                }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.displayName)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Text(summary.isSettled ? "Fully settled" : (summary.netBalance > 0 ? "Is owed" : "Owes"))
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(HiveTheme.textSecondary)
                            }
                        }
                        Spacer()
                        Text(store.currency(summary.netBalance))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(summary.isSettled ? HiveTheme.green : (summary.netBalance >= 0 ? HiveTheme.pink : HiveTheme.red))
                    }

                    GeometryReader { proxy in
                        let maxBalance = store.balanceSummaries.map { abs($0.netBalance) }.max() ?? 1
                        let ratio = maxBalance > 0 ? abs(summary.netBalance) / maxBalance : 0
                        let width = max(0, min(proxy.size.width, proxy.size.width * ratio))
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(HiveTheme.surfaceSoft)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(summary.netBalance >= 0 ? HiveTheme.pink : HiveTheme.red)
                                    .frame(width: width)
                            }
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private func expenseCard(_ expense: Expense) -> some View {
        HiveCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(expense.category.emoji)
                        Text(expense.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)
                    }
                    Text("\(store.currency(expense.amount)) total • \(store.currency(expense.totalOwed)) still owed")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                    Text("Paid by \(store.memberName(for: expense.paidByID)) • \(expense.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(HiveTheme.textSecondary)
                }

                Spacer()

                Button("Settle") {
                    withAnimation(.spring(response: 0.3)) {
                        store.settleExpense(expense)
                    }
                }
                .buttonStyle(HivePrimaryButtonStyle())
            }

            HStack(spacing: 8) {
                reactionButton("👀", expense: expense)
                reactionButton("✅", expense: expense)
                reactionButton("💸", expense: expense)

                if !expense.reactions.isEmpty {
                    Spacer()
                    ForEach(expense.reactions) { reaction in
                        Text(reaction.emoji)
                            .font(.system(size: 14))
                            .padding(4)
                            .background(HiveTheme.surfaceSoft)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func settledExpenseCard(_ expense: Expense) -> some View {
        HiveCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(expense.category.emoji)
                        Text(expense.title)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(HiveTheme.textPrimary)
                    }
                    Text("\(store.currency(expense.amount)) • Settled")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(HiveTheme.green)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(HiveTheme.green)
            }
        }
    }

    private func eventSplitCard(_ split: EventSplit) -> some View {
        HiveCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(split.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(HiveTheme.textPrimary)
                Text("\(split.confirmedCount) confirmed • \(store.currency(split.amountPerPerson ?? 0)) per person")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(HiveTheme.textSecondary)

                if let expires = split.expiresAt {
                    Text("Closes \(expires.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(HiveTheme.yellow)
                }

                HStack(spacing: 10) {
                    Button("I'm In") {
                        withAnimation(.spring(response: 0.3)) {
                            store.updateParticipation(.in, for: split)
                        }
                    }
                    .buttonStyle(HivePrimaryButtonStyle())

                    Button("Out") {
                        withAnimation(.spring(response: 0.3)) {
                            store.updateParticipation(.out, for: split)
                        }
                    }
                    .buttonStyle(HiveGhostButtonStyle(color: HiveTheme.pink))
                }
            }
        }
    }

    private func reactionButton(_ emoji: String, expense: Expense) -> some View {
        Button(emoji) {
            store.addReaction(emoji, to: expense)
        }
        .font(.system(size: 18))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(HiveTheme.surfaceSoft)
        .clipShape(Capsule())
        .foregroundStyle(HiveTheme.textPrimary)
    }
}

// MARK: - Add Expense Sheet

struct AddExpenseSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .other
    @State private var splitMethod: SplitMethod = .equal
    @State private var paidByID: UUID?
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense") {
                    TextField("What was it for?", text: $title)
                    HStack {
                        Text(store.colony.settings.currencyCode)
                            .foregroundStyle(HiveTheme.textSecondary)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Text("\(cat.emoji) \(cat.rawValue)").tag(cat)
                        }
                    }
                }

                Section("Paid By") {
                    ForEach(store.colony.members) { member in
                        Button {
                            paidByID = member.id
                        } label: {
                            HStack {
                                Text(member.displayName)
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Spacer()
                                if paidByID == member.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HiveTheme.pink)
                                }
                            }
                        }
                    }
                }

                Section("Split Method") {
                    Picker("Split", selection: $splitMethod) {
                        ForEach(SplitMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let amount = Double(amountText), amount > 0 {
                    Section("Split Preview") {
                        let perPerson = amount / Double(store.colony.members.count)
                        ForEach(store.colony.members) { member in
                            HStack {
                                Text(member.displayName)
                                    .foregroundStyle(HiveTheme.textPrimary)
                                Spacer()
                                Text(store.currency(perPerson))
                                    .foregroundStyle(HiveTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let amount = Double(amountText), amount > 0 else { return }
                        store.addExpense(
                            title: title,
                            amount: amount,
                            category: category,
                            paidByID: paidByID ?? store.currentUser.id,
                            splitMethod: splitMethod,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(amountText) == nil)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                paidByID = store.currentUser.id
            }
        }
    }
}

// MARK: - Settle Up Sheet

struct SettleUpSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: SettlementMethod = .inApp
    @State private var showingConfirmation = false
    @State private var selectedUserID: UUID?

    var body: some View {
        NavigationStack {
            List {
                Section("Payment Method") {
                    Picker("Method", selection: $selectedMethod) {
                        Text("In App").tag(SettlementMethod.inApp)
                        Text("Venmo").tag(SettlementMethod.venmo)
                        Text("Cash App").tag(SettlementMethod.cashApp)
                        Text("Zelle").tag(SettlementMethod.zelle)
                        Text("Cash").tag(SettlementMethod.cash)
                    }
                    .pickerStyle(.menu)
                }

                Section("Settle With") {
                    ForEach(store.balanceSummaries.filter { !$0.isSettled && $0.id != store.currentUser.id }) { summary in
                        Button {
                            selectedUserID = summary.id
                            showingConfirmation = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(summary.displayName)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(HiveTheme.textPrimary)
                                    Text(summary.netBalance > 0 ? "You owe them" : "They owe you")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(HiveTheme.textSecondary)
                                }
                                Spacer()
                                Text(store.currency(abs(summary.netBalance)))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(HiveTheme.pink)
                            }
                        }
                    }
                }

                if store.balanceSummaries.filter({ !$0.isSettled && $0.id != store.currentUser.id }).isEmpty {
                    Section {
                        Text("All balances are settled!")
                            .foregroundStyle(HiveTheme.green)
                    }
                }
            }
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Confirm Settlement", isPresented: $showingConfirmation) {
                Button("Settle", role: .destructive) {
                    if let userID = selectedUserID {
                        withAnimation(.spring(response: 0.3)) {
                            store.settleAllWith(userID, method: selectedMethod)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let userID = selectedUserID {
                    Text("Settle all balances with \(store.memberName(for: userID)) via \(selectedMethod.rawValue)?")
                }
            }
        }
    }
}

// MARK: - Expense Detail Sheet

struct ExpenseDetailSheet: View {
    @EnvironmentObject private var store: HiveSpaceStore
    @Environment(\.dismiss) private var dismiss
    let expense: Expense

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(expense.category.emoji)
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text(store.currency(expense.amount))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(HiveTheme.pink)
                        }
                    }
                }

                Section("Details") {
                    LabeledContent("Paid By", value: store.memberName(for: expense.paidByID))
                    LabeledContent("Category", value: expense.category.rawValue)
                    LabeledContent("Split Method", value: expense.splitMethod.rawValue)
                    LabeledContent("Date", value: expense.createdAt.formatted(date: .abbreviated, time: .shortened))
                    if expense.isFullySettled {
                        LabeledContent("Status") {
                            Text("Settled")
                                .foregroundStyle(HiveTheme.green)
                                .fontWeight(.semibold)
                        }
                    } else {
                        LabeledContent("Outstanding", value: store.currency(expense.totalOwed))
                    }
                }

                Section("Splits") {
                    ForEach(expense.splits) { split in
                        HStack {
                            Text(store.memberName(for: split.userID))
                                .foregroundStyle(HiveTheme.textPrimary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(store.currency(split.amount))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                if split.isSettled {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                        if let method = split.settledVia {
                                            Text(method.rawValue)
                                                .font(.system(size: 11))
                                        }
                                    }
                                    .foregroundStyle(HiveTheme.green)
                                } else if split.userID != expense.paidByID {
                                    Text("Pending")
                                        .font(.system(size: 11))
                                        .foregroundStyle(HiveTheme.yellow)
                                }
                            }
                        }
                    }
                }

                if let notes = expense.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                            .foregroundStyle(HiveTheme.textSecondary)
                    }
                }

                if !expense.isFullySettled {
                    Section {
                        Button("Settle This Expense") {
                            store.settleExpense(expense)
                            dismiss()
                        }
                        .buttonStyle(HivePrimaryButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExpensesView()
            .environmentObject(HiveSpaceStore.sample)
    }
}
