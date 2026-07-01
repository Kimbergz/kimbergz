import SwiftUI

// MARK: - Today view

struct FinanceView: View {
    @EnvironmentObject var appData: AppData

    private var dailyProgress: Double {
        guard appData.financeDailyLimit > 0 else { return 0 }
        return min(appData.todayTotalSpent / appData.financeDailyLimit, 1.0)
    }

    private var monthlyProgress: Double {
        guard appData.financeMonthlyLimit > 0 else { return 0 }
        return min(appData.thisMonthTotalSpent / appData.financeMonthlyLimit, 1.0)
    }

    private var overDaily: Bool {
        appData.financeDailyLimit > 0 && appData.todayTotalSpent > appData.financeDailyLimit
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Stat cards
                        HStack(spacing: 16) {
                            FinanceStatCard(
                                title: "Spent Today",
                                value: String(format: "RM %.2f", appData.todayTotalSpent),
                                icon: "creditcard.fill",
                                iconColor: overDaily ? Color(hex: "CC1016") : Color.appAccent
                            )
                            FinanceStatCard(
                                title: "This Month",
                                value: String(format: "RM %.2f", appData.thisMonthTotalSpent),
                                icon: "calendar",
                                iconColor: Color.appAccent
                            )
                        }
                        .padding(.horizontal)

                        // Daily limit progress
                        if appData.financeDailyLimit > 0 {
                            LimitProgressRow(
                                label: "Daily limit",
                                spent: appData.todayTotalSpent,
                                limit: appData.financeDailyLimit,
                                progress: dailyProgress
                            )
                            .padding(.horizontal)
                        }

                        // Monthly limit progress
                        if appData.financeMonthlyLimit > 0 {
                            LimitProgressRow(
                                label: "Monthly limit",
                                spent: appData.thisMonthTotalSpent,
                                limit: appData.financeMonthlyLimit,
                                progress: monthlyProgress
                            )
                            .padding(.horizontal)
                        }

                        // Travel reminder banner
                        HStack(spacing: 12) {
                            Image(systemName: "airplane")
                                .foregroundColor(Color.appAccent)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Remember your goal")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color.appPrimaryText)
                                Text("You're saving to travel. Every ringgit counts.")
                                    .font(.caption)
                                    .foregroundColor(Color.appSecondaryText)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.appAccent.opacity(0.08))
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // Today's entries
                        if appData.todayFinanceEntries.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "wallet.bifold")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color.appSecondaryText.opacity(0.4))
                                Text("Nothing logged yet today.")
                                    .font(.subheadline)
                                    .foregroundColor(Color.appSecondaryText)
                                Text("Tap Log below to record a transaction.")
                                    .font(.caption)
                                    .foregroundColor(Color.appSecondaryText.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Today")
                                    .font(.headline)
                                    .foregroundColor(Color.appPrimaryText)
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                ForEach(appData.todayFinanceEntries) { entry in
                                    FinanceEntryRow(entry: entry) {
                                        appData.deleteFinanceEntry(id: entry.id)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Finance")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SectionMenuButton()
                }
            }
        }
    }
}

// MARK: - Log expense view

struct LogExpenseView: View {
    @EnvironmentObject var appData: AppData

    @State private var amountText = ""
    @State private var label      = ""
    @State private var worthIt    = false
    @State private var keepIt     = true
    @State private var beneficial = false
    @State private var showBanner = false

    var amount: Double { Double(amountText) ?? 0 }
    var canSave: Bool { amount > 0 && !label.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How much did you spend?")
                                .font(.headline)
                                .foregroundColor(Color.appPrimaryText)
                            HStack(alignment: .center, spacing: 8) {
                                Text("RM")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color.appSecondaryText)
                                TextField("0.00", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(Color.appPrimaryText)
                            }
                            .padding()
                            .background(Color.appCard)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)

                        // Label
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What did you spend it on?")
                                .font(.headline)
                                .foregroundColor(Color.appPrimaryText)
                            TextField("e.g. Lunch, Grab, Groceries", text: $label)
                                .padding(12)
                                .background(Color.appCard)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Guilt questions
                        VStack(spacing: 0) {
                            Toggle(isOn: $worthIt) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Was it worth it?")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color.appPrimaryText)
                                    Text("Would you spend this again?")
                                        .font(.caption)
                                        .foregroundColor(Color.appSecondaryText)
                                }
                            }
                            .tint(Color.appAccent)
                            .padding()
                            Divider()
                            Toggle(isOn: $keepIt) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Are you keeping it?")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color.appPrimaryText)
                                    Text("Or could you return/cancel it?")
                                        .font(.caption)
                                        .foregroundColor(Color.appSecondaryText)
                                }
                            }
                            .tint(Color.appAccent)
                            .padding()
                            Divider()
                            Toggle(isOn: $beneficial) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Is it beneficial?")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color.appPrimaryText)
                                    Text("Does it help your goals or wellbeing?")
                                        .font(.caption)
                                        .foregroundColor(Color.appSecondaryText)
                                }
                            }
                            .tint(Color.appAccent)
                            .padding()
                        }
                        .background(Color.appCard)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        HStack(spacing: 10) {
                            Image(systemName: "airplane")
                                .foregroundColor(Color.appAccent)
                            Text("You're saving to travel. Is this spend necessary?")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        Button(action: save) {
                            Text("Log Expense")
                                .font(.headline)
                                .foregroundColor(canSave ? .white : Color.appSecondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canSave ? Color.appAccent : Color.appCard)
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                        .padding(.horizontal)

                        Spacer(minLength: 60)
                    }
                    .padding(.top)
                }

                if showBanner {
                    Label("Expense logged", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appAccent)
                        .cornerRadius(24)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(), value: showBanner)
            .navigationTitle("Log Expense")
        }
    }

    private func save() {
        appData.addFinanceEntry(FinanceEntry(
            amount: amount, label: label.trimmingCharacters(in: .whitespaces),
            worthIt: worthIt, keepIt: keepIt, beneficial: beneficial
        ))
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showBanner = false }
        }
        amountText = ""; label = ""; worthIt = false; keepIt = true; beneficial = false
    }
}

// MARK: - History view

struct FinanceHistoryView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                let monthly = appData.monthlySpending()

                if monthly.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(Color.appSecondaryText.opacity(0.4))
                        Text("No history yet.")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(monthly, id: \.0) { month, total in
                                VStack(alignment: .leading, spacing: 0) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(month, format: .dateTime.month(.wide).year())
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(Color.appSecondaryText)
                                        Text(String(format: "RM %.2f", total))
                                            .font(.title2.weight(.bold))
                                            .foregroundColor(Color(hex: "CC1016"))
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appCard)
                                    .cornerRadius(12)
                                    .padding(.horizontal)

                                    // Monthly progress vs limit
                                    if appData.financeMonthlyLimit > 0 {
                                        let progress = min(total / appData.financeMonthlyLimit, 1.0)
                                        LimitProgressRow(
                                            label: "of RM \(Int(appData.financeMonthlyLimit)) monthly limit",
                                            spent: total,
                                            limit: appData.financeMonthlyLimit,
                                            progress: progress
                                        )
                                        .padding(.horizontal)
                                    }

                                    // Day entries for this month
                                    let days = appData.financeEntriesByDay().filter {
                                        Calendar.current.isDate($0.0, equalTo: month, toGranularity: .month)
                                    }
                                    ForEach(days, id: \.0) { day, entries in
                                        VStack(alignment: .leading, spacing: 0) {
                                            HStack {
                                                Text(day, style: .date)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundColor(Color.appSecondaryText)
                                                Spacer()
                                                let dayTotal = entries.reduce(0.0) { $0 + $1.amount }
                                                Text(String(format: "RM %.2f", dayTotal))
                                                    .font(.caption)
                                                    .foregroundColor(Color(hex: "CC1016"))
                                            }
                                            .padding(.horizontal)
                                            .padding(.top, 8)
                                            .padding(.bottom, 4)

                                            ForEach(entries.sorted { $0.date < $1.date }) { entry in
                                                FinanceEntryRow(entry: entry) {
                                                    appData.deleteFinanceEntry(id: entry.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer(minLength: 20)
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

// MARK: - Goals view

struct FinanceGoalsView: View {
    @EnvironmentObject var appData: AppData

    @State private var dailyText   = ""
    @State private var monthlyText = ""
    @State private var showBanner  = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Current limits summary
                        HStack(spacing: 16) {
                            FinanceStatCard(
                                title: "Daily Limit",
                                value: appData.financeDailyLimit > 0 ? String(format: "RM %.0f", appData.financeDailyLimit) : "Not set",
                                icon: "sun.max.fill",
                                iconColor: Color.appAccent
                            )
                            FinanceStatCard(
                                title: "Monthly Limit",
                                value: appData.financeMonthlyLimit > 0 ? String(format: "RM %.0f", appData.financeMonthlyLimit) : "Not set",
                                icon: "calendar",
                                iconColor: Color.appAccent
                            )
                        }
                        .padding(.horizontal)

                        // Set limits
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Daily spending limit")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color.appPrimaryText)
                                    Text("Max you allow yourself to spend per day")
                                        .font(.caption)
                                        .foregroundColor(Color.appSecondaryText)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("RM")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color.appSecondaryText)
                                    TextField("e.g. 50", text: $dailyText)
                                        .keyboardType(.decimalPad)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(Color.appAccent)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                }
                            }
                            .padding()

                            Divider()

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Monthly spending limit")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color.appPrimaryText)
                                    Text("Max you allow yourself to spend per month")
                                        .font(.caption)
                                        .foregroundColor(Color.appSecondaryText)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("RM")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color.appSecondaryText)
                                    TextField("e.g. 1000", text: $monthlyText)
                                        .keyboardType(.decimalPad)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(Color.appAccent)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                }
                            }
                            .padding()
                        }
                        .background(Color.appCard)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // Travel context
                        HStack(spacing: 12) {
                            Image(systemName: "airplane")
                                .foregroundColor(Color.appAccent)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Saving for travel")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color.appPrimaryText)
                                Text("Set limits that keep you on track toward your trip.")
                                    .font(.caption)
                                    .foregroundColor(Color.appSecondaryText)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.appAccent.opacity(0.08))
                        .cornerRadius(14)
                        .padding(.horizontal)

                        Button(action: save) {
                            Text("Save Goals")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appAccent)
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        Spacer(minLength: 60)
                    }
                    .padding(.top)
                }

                if showBanner {
                    Label("Goals saved", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appAccent)
                        .cornerRadius(24)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(), value: showBanner)
            .navigationTitle("Goals")
            .onAppear {
                if appData.financeDailyLimit > 0   { dailyText   = String(format: "%.0f", appData.financeDailyLimit) }
                if appData.financeMonthlyLimit > 0 { monthlyText = String(format: "%.0f", appData.financeMonthlyLimit) }
            }
        }
    }

    private func save() {
        if let d = Double(dailyText)   { appData.saveFinanceDailyLimit(d) }
        if let m = Double(monthlyText) { appData.saveFinanceMonthlyLimit(m) }
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showBanner = false }
        }
    }
}

// MARK: - Shared components

struct LimitProgressRow: View {
    let label    : String
    let spent    : Double
    let limit    : Double
    let progress : Double

    private var over: Bool { spent > limit }
    private var barColor: Color { over ? Color(hex: "CC1016") : Color.appAccent }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.appSecondaryText)
                Spacer()
                Text(String(format: "RM %.2f / RM %.0f", spent, limit))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(over ? Color(hex: "CC1016") : Color.appPrimaryText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.appPrimaryText.opacity(0.1))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(12)
    }
}

struct FinanceStatCard: View {
    let title:     String
    let value:     String
    let icon:      String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.appCard)
        .cornerRadius(16)
    }
}

struct FinanceEntryRow: View {
    let entry: FinanceEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.appPrimaryText)
                HStack(spacing: 8) {
                    if entry.worthIt {
                        Label("Worth it", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(Color(hex: "057642"))
                    } else {
                        Label("Not worth it", systemImage: "xmark.circle.fill")
                            .font(.caption).foregroundColor(Color(hex: "CC1016"))
                    }
                    if entry.beneficial {
                        Label("Beneficial", systemImage: "arrow.up.circle.fill")
                            .font(.caption).foregroundColor(Color.appAccent)
                    }
                    if !entry.keepIt {
                        Label("Returnable", systemImage: "arrow.uturn.left.circle")
                            .font(.caption).foregroundColor(Color.appSecondaryText)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "RM %.2f", entry.amount))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color(hex: "CC1016"))
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
