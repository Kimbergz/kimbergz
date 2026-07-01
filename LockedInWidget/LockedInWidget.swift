import WidgetKit
import SwiftUI

// MARK: - Timeline entry

struct StudyEntry: TimelineEntry {
    let date: Date
    let todayMinutes: Int
    let goalMinutes: Int
    let streak: Int
}

// MARK: - Provider

struct StudyProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudyEntry {
        StudyEntry(date: Date(), todayMinutes: 90, goalMinutes: 150, streak: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyEntry>) -> Void) {
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [loadEntry()], policy: .after(refresh)))
    }

    private func loadEntry() -> StudyEntry {
        let defaults = UserDefaults(suiteName: "group.al.akm.lockedin") ?? .standard
        var todayMins = 0
        var streak    = 0
        let goalMins  = defaults.integer(forKey: "lockedin_goal_minutes")

        if let data     = defaults.data(forKey: "lockedin_sessions"),
           let sessions = try? JSONDecoder().decode([StudySession].self, from: data) {
            let cal = Calendar.current
            todayMins = sessions
                .filter { cal.isDateInToday($0.date) }
                .reduce(0) { $0 + $1.durationMinutes }

            var check = cal.startOfDay(for: Date())
            while sessions.contains(where: { cal.isDate($0.date, inSameDayAs: check) }) {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: check) else { break }
                check = prev
            }
        }
        return StudyEntry(date: Date(), todayMinutes: todayMins, goalMinutes: goalMins, streak: streak)
    }
}

// MARK: - Colors

private let accentBlue   = Color(red: 0.039, green: 0.400, blue: 0.761) // #0a66c2
private let primaryBlue  = Color(red: 0,     green: 0.255, blue: 0.510) // #004182
private let bgColor      = Color(red: 0.992, green: 0.980, blue: 0.961) // #fdfaf5
private let cardColor    = Color(red: 0.914, green: 0.898, blue: 0.875) // #e9e5df
private let secondaryGray = Color(red: 0.369, green: 0.369, blue: 0.369) // #5E5E5E

// MARK: - Small widget

struct WidgetSmall: View {
    let entry: StudyEntry

    private var goalMet: Bool { entry.goalMinutes > 0 && entry.todayMinutes >= entry.goalMinutes }
    private var progress: Double {
        guard entry.goalMinutes > 0 else { return 0 }
        return min(Double(entry.todayMinutes) / Double(entry.goalMinutes), 1.0)
    }

    var body: some View {
        ZStack {
            bgColor
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("🔒")
                        .font(.caption2)
                    Text("LockedIn")
                        .font(.caption.weight(.bold))
                        .foregroundColor(accentBlue)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(primaryBlue.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accentBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        Text(widgetFormatMinutes(entry.todayMinutes))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(primaryBlue)
                        if entry.goalMinutes > 0 {
                            Text("/ \(widgetFormatMinutes(entry.goalMinutes))")
                                .font(.system(size: 8))
                                .foregroundColor(secondaryGray)
                        }
                    }
                }
                .frame(width: 70, height: 70)

                Spacer()

                HStack {
                    Text(goalMet ? "💪 Goal met!" : "🔥 \(entry.streak) day streak")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(goalMet ? accentBlue : secondaryGray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Medium widget

struct WidgetMedium: View {
    let entry: StudyEntry

    private var goalMet: Bool { entry.goalMinutes > 0 && entry.todayMinutes >= entry.goalMinutes }
    private var progress: Double {
        guard entry.goalMinutes > 0 else { return 0 }
        return min(Double(entry.todayMinutes) / Double(entry.goalMinutes), 1.0)
    }
    private var statusMessage: String {
        if goalMet { return "You're doing great! 💪" }
        if entry.todayMinutes == 0 { return "Doing awful today. Let's get some studying in!" }
        return "Doing awful today. Let's get some studying in!"
    }

    var body: some View {
        ZStack {
            bgColor
            HStack(spacing: 16) {
                // Left: ring + time
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(primaryBlue.opacity(0.15), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(accentBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text(widgetFormatMinutes(entry.todayMinutes))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(primaryBlue)
                            if entry.goalMinutes > 0 {
                                Text("/ \(widgetFormatMinutes(entry.goalMinutes))")
                                    .font(.system(size: 9))
                                    .foregroundColor(secondaryGray)
                            }
                        }
                    }
                    .frame(width: 100, height: 100)

                    Text("🔥 \(entry.streak) day\(entry.streak == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(secondaryGray)
                }

                // Right: message
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("🔒")
                            .font(.caption)
                        Text("LockedIn")
                            .font(.caption.weight(.bold))
                            .foregroundColor(accentBlue)
                    }

                    Spacer()

                    Text(statusMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryBlue)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    if !goalMet && entry.goalMinutes > 0 {
                        let remaining = entry.goalMinutes - entry.todayMinutes
                        Text("\(widgetFormatMinutes(max(0, remaining))) left to goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(accentBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentBlue.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
    }
}

// MARK: - Dispatcher

struct StudyWidgetView: View {
    let entry: StudyEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:  WidgetSmall(entry: entry)
        default:            WidgetMedium(entry: entry)
        }
    }
}

// MARK: - Widget

struct StudyWidget: Widget {
    let kind = "LockedInWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudyProvider()) { entry in
            if #available(iOS 17.0, *) {
                StudyWidgetView(entry: entry)
                    .containerBackground(Color(red: 0.992, green: 0.980, blue: 0.961), for: .widget)
            } else {
                StudyWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("LockedIn")
        .description("Today's study time and streak")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private func widgetFormatMinutes(_ mins: Int) -> String {
    let h = mins / 60, m = mins % 60
    if h > 0 && m > 0 { return "\(h)h \(m)m" }
    if h > 0           { return "\(h)h" }
    return "\(m)m"
}
