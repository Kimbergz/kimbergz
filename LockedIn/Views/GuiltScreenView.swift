import SwiftUI

struct GuiltScreenView: View {
    @EnvironmentObject var appData: AppData
    let onDismiss: () -> Void

    private var studiedMinutes: Int { appData.todayTotalMinutes }
    private var goalMinutes: Int    { appData.totalDailyGoalMinutes }
    private var remaining: Int      { appData.minutesRemainingToday }
    private var dismissCount: Int   { appData.todayDismissCount }
    private var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(Double(studiedMinutes) / Double(goalMinutes), 1.0)
    }

    private var goalMet: Bool { appData.dailyGoalMet }

    private var guiltMessage: String {
        if goalMet {
            return "You've studied \(formatMinutes(studiedMinutes)) today. Congrats."
        } else if studiedMinutes == 0 {
            return "You haven't studied at all today."
        } else {
            return "You've only studied \(formatMinutes(studiedMinutes)) today."
        }
    }

    private var subMessage: String {
        if goalMet {
            return "Don't lose the momentum by doomscrolling!"
        } else {
            return "Are you sure you want to keep scrolling?"
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: goalMet ? "checkmark.seal.fill" : "lock.fill")
                    .font(.system(size: 64))
                    .foregroundColor(goalMet ? Color(hex: "057642") : Color.appAccent)

                VStack(spacing: 12) {
                    Text(guiltMessage)
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color.appPrimaryText)
                        .multilineTextAlignment(.center)

                    Text(subMessage)
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.appPrimaryText.opacity(0.12), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.appAccent,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: progress)

                    VStack(spacing: 4) {
                        Text(formatMinutes(studiedMinutes))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color.appPrimaryText)
                        Text("of \(formatMinutes(goalMinutes)) goal")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    }
                }
                .frame(width: 180, height: 180)

                if !goalMet && remaining > 0 {
                    Text("\(formatMinutes(remaining)) remaining to hit your goal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.appAccent)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.appAccent.opacity(0.1))
                        .cornerRadius(12)
                }

                Spacer()

                if !goalMet && dismissCount > 0 {
                    Text("You've skipped your goals \(dismissCount) time\(dismissCount == 1 ? "" : "s") today.")
                        .font(.caption)
                        .foregroundColor(Color(hex: "CC1016"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Go study — dismiss without incrementing counter
                        onDismiss()
                    }) {
                        Text("Lock In Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appAccent)
                            .cornerRadius(14)
                    }

                    Button(action: {
                        appData.recordDismiss()
                        onDismiss()
                    }) {
                        Text("I'll study later...")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
