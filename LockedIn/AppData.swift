import Foundation
import SwiftUI
import WidgetKit
import UserNotifications

class AppData: ObservableObject {
    private let defaults: UserDefaults
    private let sessionsKey    = "lockedin_sessions"
    private let subjectsKey    = "lockedin_subjects"
    private let dismissKey     = "lockedin_dismiss_count"
    private let dismissDateKey = "lockedin_dismiss_date"
    private let dietKey        = "lockedin_diet_entries"
    private let financeKey          = "lockedin_finance_entries"
    private let financeDailyKey     = "lockedin_finance_daily_limit"
    private let financeMonthlyKey   = "lockedin_finance_monthly_limit"
    private let dietCalorieGoalKey  = "lockedin_diet_calorie_goal"

    @Published var sessions:            [StudySession]   = []
    @Published var subjects:            [Subject]        = []
    @Published var dietEntries:         [DietEntry]      = []
    @Published var financeEntries:      [FinanceEntry]   = []
    @Published var todayDismissCount:   Int              = 0
    @Published var financeDailyLimit:   Double           = 0
    @Published var financeMonthlyLimit: Double           = 0
    @Published var dietDailyCalorieGoal: Double          = 0

    init() {
        self.defaults = UserDefaults(suiteName: "group.al.akm.lockedin") ?? .standard
        load()
        loadDismissCount()
        if subjects.isEmpty {
            subjects = [
                Subject(name: "Mathematics", dailyGoalMinutes: 60, colorHex: "0a66c2"),
                Subject(name: "English",     dailyGoalMinutes: 45, colorHex: "057642"),
                Subject(name: "Science",     dailyGoalMinutes: 60, colorHex: "004182"),
            ]
            saveSubjects()
        }
        loadDiet()
        loadFinance()
        financeDailyLimit   = defaults.double(forKey: financeDailyKey)
        financeMonthlyLimit = defaults.double(forKey: financeMonthlyKey)
        dietDailyCalorieGoal = defaults.double(forKey: dietCalorieGoalKey)
        scheduleAllNotifications()
    }

    // MARK: - Computed

    var todaySessions: [StudySession] {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.date) }
    }

    var todayTotalMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalDailyGoalMinutes: Int {
        subjects.reduce(0) { $0 + $1.dailyGoalMinutes }
    }

    var minutesRemainingToday: Int {
        max(0, totalDailyGoalMinutes - todayTotalMinutes)
    }

    var dailyGoalMet: Bool {
        totalDailyGoalMinutes > 0 && todayTotalMinutes >= totalDailyGoalMinutes
    }

    var streak: Int {
        var count = 0
        let cal = Calendar.current
        var checkDate = cal.startOfDay(for: Date())
        while sessions.contains(where: { cal.isDate($0.date, inSameDayAs: checkDate) }) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return count
    }

    func todayMinutes(for subject: String) -> Int {
        todaySessions.filter { $0.subject == subject }.reduce(0) { $0 + $1.durationMinutes }
    }

    func sessionsByDay() -> [(Date, [StudySession])] {
        let cal = Calendar.current
        var grouped: [Date: [StudySession]] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.date)
            grouped[day, default: []].append(s)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    // MARK: - Weekly stats

    func weeklyStats() -> (totalMinutes: Int, topSubject: String, topMinutes: Int) {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekSessions = sessions.filter { $0.date >= weekAgo }
        let total = weekSessions.reduce(0) { $0 + $1.durationMinutes }
        var bySubject: [String: Int] = [:]
        for s in weekSessions {
            bySubject[s.subject, default: 0] += s.durationMinutes
        }
        let top = bySubject.max(by: { $0.value < $1.value })
        return (total, top?.key ?? "", top?.value ?? 0)
    }

    // MARK: - Diet

    var todayDietEntries: [DietEntry] {
        let cal = Calendar.current
        return dietEntries.filter { cal.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    var todayCalories: Double { todayDietEntries.reduce(0) { $0 + $1.calories } }
    var todayProtein:  Double { todayDietEntries.reduce(0) { $0 + $1.protein  } }
    var todayCarbs:    Double { todayDietEntries.reduce(0) { $0 + $1.carbs    } }
    var todayFats:     Double { todayDietEntries.reduce(0) { $0 + $1.fats     } }
    var todayFiber:    Double { todayDietEntries.reduce(0) { $0 + $1.fiber    } }

    var lastMealTime: Date? { todayDietEntries.last?.date }

    func addDietEntry(_ entry: DietEntry) {
        dietEntries.append(entry)
        saveDiet()
    }

    func deleteDietEntry(id: UUID) {
        dietEntries.removeAll { $0.id == id }
        saveDiet()
    }

    func dietEntriesByDay() -> [(Date, [DietEntry])] {
        let cal = Calendar.current
        var grouped: [Date: [DietEntry]] = [:]
        for e in dietEntries {
            let day = cal.startOfDay(for: e.date)
            grouped[day, default: []].append(e)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    // MARK: - Finance

    var todayFinanceEntries: [FinanceEntry] {
        let cal = Calendar.current
        return financeEntries.filter { cal.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    var todayTotalSpent: Double { todayFinanceEntries.reduce(0) { $0 + $1.amount } }

    var thisMonthTotalSpent: Double {
        let cal = Calendar.current
        let now = Date()
        return financeEntries
            .filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    func monthlySpending() -> [(Date, Double)] {
        let cal = Calendar.current
        var grouped: [Date: Double] = [:]
        for e in financeEntries {
            let month = cal.date(from: cal.dateComponents([.year, .month], from: e.date)) ?? e.date
            grouped[month, default: 0] += e.amount
        }
        return grouped.sorted { $0.key > $1.key }
    }

    func saveFinanceDailyLimit(_ v: Double) {
        financeDailyLimit = v
        defaults.set(v, forKey: financeDailyKey)
    }

    func saveFinanceMonthlyLimit(_ v: Double) {
        financeMonthlyLimit = v
        defaults.set(v, forKey: financeMonthlyKey)
    }

    func saveDietCalorieGoal(_ v: Double) {
        dietDailyCalorieGoal = v
        defaults.set(v, forKey: dietCalorieGoalKey)
    }

    func addFinanceEntry(_ entry: FinanceEntry) {
        financeEntries.append(entry)
        saveFinance()
    }

    func deleteFinanceEntry(id: UUID) {
        financeEntries.removeAll { $0.id == id }
        saveFinance()
    }

    func financeEntriesByDay() -> [(Date, [FinanceEntry])] {
        let cal = Calendar.current
        var grouped: [Date: [FinanceEntry]] = [:]
        for e in financeEntries {
            let day = cal.startOfDay(for: e.date)
            grouped[day, default: []].append(e)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    // MARK: - Dismiss counter

    func recordDismiss() {
        todayDismissCount += 1
        defaults.set(todayDismissCount, forKey: dismissKey)
        defaults.set(Date(), forKey: dismissDateKey)
    }

    private func loadDismissCount() {
        let cal = Calendar.current
        if let lastDate = defaults.object(forKey: dismissDateKey) as? Date,
           cal.isDateInToday(lastDate) {
            todayDismissCount = defaults.integer(forKey: dismissKey)
        } else {
            todayDismissCount = 0
        }
    }

    // MARK: - Mutations

    func addSession(_ session: StudySession) {
        sessions.append(session)
        saveSessions()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }

    func addSubject(_ s: Subject) {
        subjects.append(s)
        saveSubjects()
    }

    func updateSubject(_ s: Subject) {
        guard let i = subjects.firstIndex(where: { $0.id == s.id }) else { return }
        subjects[i] = s
        saveSubjects()
    }

    func deleteSubject(id: UUID) {
        subjects.removeAll { $0.id == id }
        saveSubjects()
    }

    // MARK: - Persistence

    private func load() {
        if let data = defaults.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([StudySession].self, from: data) {
            sessions = decoded
        }
        if let data = defaults.data(forKey: subjectsKey),
           let decoded = try? JSONDecoder().decode([Subject].self, from: data) {
            subjects = decoded
        }
    }

    private func loadDiet() {
        if let data = defaults.data(forKey: dietKey),
           let decoded = try? JSONDecoder().decode([DietEntry].self, from: data) {
            dietEntries = decoded
        }
    }

    private func saveDiet() {
        if let encoded = try? JSONEncoder().encode(dietEntries) {
            defaults.set(encoded, forKey: dietKey)
        }
    }

    private func loadFinance() {
        if let data = defaults.data(forKey: financeKey),
           let decoded = try? JSONDecoder().decode([FinanceEntry].self, from: data) {
            financeEntries = decoded
        }
    }

    private func saveFinance() {
        if let encoded = try? JSONEncoder().encode(financeEntries) {
            defaults.set(encoded, forKey: financeKey)
        }
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            defaults.set(encoded, forKey: sessionsKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveSubjects() {
        if let encoded = try? JSONEncoder().encode(subjects) {
            defaults.set(encoded, forKey: subjectsKey)
        }
        defaults.set(totalDailyGoalMinutes, forKey: "lockedin_goal_minutes")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Notifications

    func scheduleAllNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { self.rescheduleNotifications() }
        }
    }

    func rescheduleNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "lockedin_morning", "lockedin_midday", "lockedin_evening",
            "lockedin_streak", "lockedin_weekly",
            "diet_morning", "diet_noon", "diet_afternoon",
            "diet_late_afternoon", "diet_evening", "diet_night",
            "finance_morning", "finance_afternoon", "finance_evening", "finance_night"
        ])

        let goalMins = totalDailyGoalMinutes
        let goalText = formatMinutes(goalMins)

        scheduleDaily(id: "lockedin_morning", hour: 8, minute: 0,
            title: "Time to lock in.",
            body: "Your goal today is \(goalText) of study. Let's get it.")

        scheduleDaily(id: "lockedin_midday", hour: 13, minute: 0,
            title: "Midday check-in",
            body: "You haven't studied yet today. \(goalText) to hit your goal.")

        scheduleDaily(id: "lockedin_evening", hour: 20, minute: 0,
            title: "Evening warning",
            body: "\(goalText) left to hit your goal today. Don't break the streak.")

        scheduleDaily(id: "lockedin_streak", hour: 22, minute: 0,
            title: "Streak at risk",
            body: "You haven't studied at all today. Log something before midnight.")

        scheduleWeekly(id: "lockedin_weekly", weekday: 1, hour: 19, minute: 0)

        scheduleFinanceNotifications()

        scheduleDiet(id: "diet_morning",       hour: 9,  minute: 0,
            title: "Did you eat yet?",
            body: "Have you eaten anything today? Log it.")
        scheduleDiet(id: "diet_noon",          hour: 12, minute: 0,
            title: "Lunchtime check-in",
            body: "Have you eaten anything since this morning? Log it.")
        scheduleDiet(id: "diet_afternoon",     hour: 14, minute: 30,
            title: "Afternoon check-in",
            body: "Have you eaten anything since noon? Log it.")
        scheduleDiet(id: "diet_late_afternoon",hour: 17, minute: 0,
            title: "Still eating?",
            body: "Have you eaten anything since 2:30pm? Log it.")
        scheduleDiet(id: "diet_evening",       hour: 19, minute: 30,
            title: "Evening check-in",
            body: "Have you eaten anything since 5pm? Log it.")
        scheduleDiet(id: "diet_night",         hour: 22, minute: 0,
            title: "Last call 🍽️",
            body: "Have you eaten since 7:30pm? Log everything before midnight.")
    }

    private func scheduleFinanceNotifications() {
        scheduleFinance(id: "finance_morning",   hour: 10, minute: 30,
            title: "Spending check",
            body: "Have you spent any money this morning? Log it. You're saving for travel.")
        scheduleFinance(id: "finance_afternoon", hour: 15, minute: 0,
            title: "Afternoon check",
            body: "Any spending since this morning? Every ringgit you save is a step closer to your trip.")
        scheduleFinance(id: "finance_evening",   hour: 18, minute: 30,
            title: "Evening spending check",
            body: "What have you spent today? Log it and stay honest with yourself.")
        scheduleFinance(id: "finance_night",     hour: 21, minute: 0,
            title: "End of day — finances",
            body: "Last check. Review today's spending. Remember why you're saving: travel.")
    }

    private func scheduleFinance(id: String, hour: Int, minute: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title            = title
        content.body             = body
        content.sound            = .default
        content.userInfo         = ["type": "finance"]

        var comps = DateComponents()
        comps.hour   = hour
        comps.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleDiet(id: String, hour: Int, minute: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title            = title
        content.body             = body
        content.sound            = .default
        content.userInfo         = ["type": "diet"]
        content.categoryIdentifier = "DIET_LOG"

        var comps = DateComponents()
        comps.hour   = hour
        comps.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleDaily(id: String, hour: Int, minute: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        var comps = DateComponents()
        comps.hour   = hour
        comps.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleWeekly(id: String, weekday: Int, hour: Int, minute: Int) {
        let stats = weeklyStats()
        let totalHours = String(format: "%.1f", Double(stats.totalMinutes) / 60.0)

        let content = UNMutableNotificationContent()
        content.title = "Weekly Report"
        content.sound = .default

        if stats.topSubject.isEmpty {
            content.body = "This week you studied \(totalHours) hours total."
        } else {
            let topHours = String(format: "%.1f", Double(stats.topMinutes) / 60.0)
            content.body = "This week you studied \(totalHours) hours total. Top subject: \(stats.topSubject) at \(topHours) hours."
        }

        var comps = DateComponents()
        comps.weekday = weekday
        comps.hour    = hour
        comps.minute  = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
