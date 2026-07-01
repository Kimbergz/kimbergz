import SwiftUI

struct DietView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Calorie goal progress
                        if appData.dietDailyCalorieGoal > 0 {
                            let progress = min(appData.todayCalories / appData.dietDailyCalorieGoal, 1.0)
                            let over = appData.todayCalories > appData.dietDailyCalorieGoal
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Daily calorie goal")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color.appSecondaryText)
                                    Spacer()
                                    Text("\(Int(appData.todayCalories)) / \(Int(appData.dietDailyCalorieGoal)) kcal")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(over ? Color(hex: "CC1016") : Color.appPrimaryText)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.appPrimaryText.opacity(0.1))
                                            .frame(height: 8)
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(over ? Color(hex: "CC1016") : Color.appAccent)
                                            .frame(width: geo.size.width * progress, height: 8)
                                            .animation(.easeOut(duration: 0.5), value: progress)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding()
                            .background(Color.appCard)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        if !appData.todayDietEntries.isEmpty {
                            // Today macro summary
                            VStack(spacing: 12) {
                                Text("Today")
                                    .font(.headline)
                                    .foregroundColor(Color.appPrimaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                MacroGrid(
                                    calories: appData.todayCalories,
                                    protein:  appData.todayProtein,
                                    carbs:    appData.todayCarbs,
                                    fats:     appData.todayFats,
                                    fiber:    appData.todayFiber
                                )
                            }
                            .padding(.horizontal)

                            // Today's meals
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Meals")
                                    .font(.headline)
                                    .foregroundColor(Color.appPrimaryText)
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)

                                ForEach(appData.todayDietEntries) { entry in
                                    DietEntryRow(entry: entry) {
                                        appData.deleteDietEntry(id: entry.id)
                                    }
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color.appSecondaryText.opacity(0.5))
                                Text("Nothing logged yet today.")
                                    .font(.subheadline)
                                    .foregroundColor(Color.appSecondaryText)
                                Text("Tap Log below to add your first meal.")
                                    .font(.caption)
                                    .foregroundColor(Color.appSecondaryText.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Diet")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SectionMenuButton()
                }
            }
        }
    }
}

struct DietHistoryView: View {
    @EnvironmentObject var appData: AppData

    private var history: [(Date, [DietEntry])] {
        appData.dietEntriesByDay()
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(Color.appSecondaryText.opacity(0.5))
                        Text("No history yet.")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(history, id: \.0) { day, entries in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(dayLabel(day))
                                            .font(.subheadline.weight(.bold))
                                            .foregroundColor(Color.appPrimaryText)
                                        Spacer()
                                        Text("\(entries.count) meal\(entries.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(Color.appSecondaryText)
                                    }

                                    let totalCal     = entries.reduce(0.0) { $0 + $1.calories }
                                    let totalProtein = entries.reduce(0.0) { $0 + $1.protein }
                                    let totalCarbs   = entries.reduce(0.0) { $0 + $1.carbs }
                                    let totalFats    = entries.reduce(0.0) { $0 + $1.fats }
                                    let totalFiber   = entries.reduce(0.0) { $0 + $1.fiber }

                                    HStack(spacing: 0) {
                                        DayStat(label: "Calories", value: "\(Int(totalCal))",    unit: "kcal", color: Color.appAccent)
                                        Divider().frame(height: 30)
                                        DayStat(label: "Protein",  value: "\(Int(totalProtein))", unit: "g",   color: Color(hex: "057642"))
                                        Divider().frame(height: 30)
                                        DayStat(label: "Carbs",    value: "\(Int(totalCarbs))",  unit: "g",    color: Color(hex: "b24020"))
                                        Divider().frame(height: 30)
                                        DayStat(label: "Fats",     value: "\(Int(totalFats))",   unit: "g",    color: Color(hex: "a37c00"))
                                        Divider().frame(height: 30)
                                        DayStat(label: "Fiber",    value: "\(Int(totalFiber))",  unit: "g",    color: Color(hex: "5E5E5E"))
                                    }
                                }
                                .padding()
                                .background(Color.appCard)
                                .cornerRadius(14)
                                .padding(.horizontal)
                            }
                            Spacer(minLength: 20)
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Diet History")
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: date)
    }
}

struct DayStat: View {
    let label: String
    let value: String
    let unit:  String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
            Text(unit)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.appSecondaryText)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared components

struct MacroGrid: View {
    let calories: Double
    let protein:  Double
    let carbs:    Double
    let fats:     Double
    let fiber:    Double

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                MacroCell(label: "Calories", value: calories, unit: "kcal", color: Color.appAccent)
                MacroCell(label: "Protein",  value: protein,  unit: "g",    color: Color(hex: "057642"))
            }
            HStack {
                MacroCell(label: "Carbs",    value: carbs,    unit: "g",    color: Color(hex: "b24020"))
                MacroCell(label: "Fats",     value: fats,     unit: "g",    color: Color(hex: "a37c00"))
                MacroCell(label: "Fiber",    value: fiber,    unit: "g",    color: Color(hex: "5E5E5E"))
            }
        }
    }
}

struct MacroCell: View {
    let label: String
    let value: Double
    let unit:  String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value < 10 ? String(format: "%.1f", value) : "\(Int(value))")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            Text("\(unit)  \(label)")
                .font(.caption)
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.appCard)
        .cornerRadius(12)
    }
}

struct DietEntryRow: View {
    let entry: DietEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.appPrimaryText)
                HStack(spacing: 6) {
                    MacroPill(label: "\(Int(entry.calories)) kcal", color: Color.appAccent)
                    MacroPill(label: "P \(Int(entry.protein))g",    color: Color(hex: "057642"))
                    MacroPill(label: "C \(Int(entry.carbs))g",      color: Color(hex: "b24020"))
                    MacroPill(label: "F \(Int(entry.fats))g",       color: Color(hex: "a37c00"))
                }
                HStack(spacing: 8) {
                    Text(entry.feeling.rawValue)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                    if entry.guilty {
                        Label("Guilty", systemImage: "exclamationmark.circle.fill")
                            .font(.caption).foregroundColor(Color.appSecondaryText)
                    }
                    if entry.tasty {
                        Label("Good", systemImage: "hand.thumbsup.fill")
                            .font(.caption).foregroundColor(Color.appSecondaryText)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText.opacity(0.6))
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

struct MacroPill: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

extension Notification.Name {
    static let openDietLog = Notification.Name("openDietLog")
}
