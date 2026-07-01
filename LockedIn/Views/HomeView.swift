import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatCard(title: "Streak", value: "\(appData.streak)", icon: "flame.fill",  iconColor: Color(hex: "E68523"))
                            StatCard(title: "Today",  value: formatMinutes(appData.todayTotalMinutes), icon: "clock.fill", iconColor: Color.appAccent)
                        }

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Subject Progress")
                                .font(.headline)
                                .foregroundColor(Color.appPrimaryText)
                                .padding(.horizontal)
                                .padding(.bottom, 10)

                            if appData.subjects.isEmpty {
                                Text("Add subjects in Goals →")
                                    .foregroundColor(Color.appSecondaryText)
                                    .font(.subheadline)
                                    .padding()
                            } else {
                                ForEach(appData.subjects) { subject in
                                    SubjectProgressRow(
                                        subject: subject,
                                        minutesStudied: appData.todayMinutes(for: subject.name)
                                    )
                                    .padding(.bottom, 10)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("LockedIn")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SectionMenuButton()
                }
            }
        }
    }
}

struct StatCard: View {
    let title:     String
    let value:     String
    let icon:      String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
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

struct SubjectProgressRow: View {
    let subject: Subject
    let minutesStudied: Int

    var progress: Double {
        guard subject.dailyGoalMinutes > 0 else { return 0 }
        return min(Double(minutesStudied) / Double(subject.dailyGoalMinutes), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(Color(hex: subject.colorHex))
                    .frame(width: 10, height: 10)
                Text(subject.name)
                    .foregroundColor(Color.appPrimaryText)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(formatMinutes(minutesStudied)) / \(formatMinutes(subject.dailyGoalMinutes))")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.appPrimaryText.opacity(0.12))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: subject.colorHex))
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(14)
    }
}
