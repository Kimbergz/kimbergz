import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if appData.sessions.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 52))
                            .foregroundColor(Color.appSecondaryText.opacity(0.4))
                        Text("No sessions yet")
                            .foregroundColor(Color.appSecondaryText)
                        Text("Log your first study session.")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText.opacity(0.7))
                    }
                } else {
                    List {
                        ForEach(appData.sessionsByDay(), id: \.0) { (day, daySessions) in
                            Section {
                                ForEach(daySessions.sorted { $0.date > $1.date }) { session in
                                    SessionRow(session: session)
                                        .listRowBackground(Color.appCard)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    appData.deleteSession(id: session.id)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                HStack {
                                    Text(dayLabel(day))
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color.appAccent)
                                    Spacer()
                                    let total = daySessions.reduce(0) { $0 + $1.durationMinutes }
                                    Text(formatMinutes(total))
                                        .font(.caption)
                                        .foregroundColor(Color.appSecondaryText)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
        }
    }

    func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: date)
    }
}

struct SessionRow: View {
    let session: StudySession

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.subject)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.appPrimaryText)
                    if session.isPomodoro {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundColor(Color.appAccent)
                    }
                }
                if let difficulty = session.difficulty {
                    Text(difficulty.rawValue)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
            Spacer()
            Text(formatMinutes(session.durationMinutes))
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.appAccent)
        }
        .padding(.vertical, 4)
    }
}
