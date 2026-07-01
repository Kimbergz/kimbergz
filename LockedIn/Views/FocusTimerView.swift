import SwiftUI
import UserNotifications

enum TimerPhase: String {
    case work       = "Focus"
    case shortBreak = "Short Break"
    case longBreak  = "Long Break"

    var totalSeconds: Int {
        switch self {
        case .work:       return 25 * 60
        case .shortBreak: return  5 * 60
        case .longBreak:  return 15 * 60
        }
    }

    var color: Color {
        switch self {
        case .work:       return Color(hex: "0a66c2")
        case .shortBreak: return Color(hex: "057642")
        case .longBreak:  return Color(hex: "004182")
        }
    }
}

class PomodoroTimer: ObservableObject {
    @Published var phase: TimerPhase = .work
    @Published var secondsRemaining: Int = TimerPhase.work.totalSeconds
    @Published var isRunning: Bool = false
    @Published var completedPomodoros: Int = 0
    @Published var selectedSubject: String = ""

    weak var appData: AppData?

    private var timer: Timer?
    private var backgroundDate: Date?

    var timeString: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    var ringProgress: Double {
        1.0 - Double(secondsRemaining) / Double(phase.totalSeconds)
    }

    func start() {
        requestNotificationPermission()
        isRunning = true
        scheduleNotification()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.complete()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["lockedin_timer"])
    }

    func reset() {
        pause()
        secondsRemaining = phase.totalSeconds
    }

    func skip() {
        complete()
    }

    func handleBackground() {
        if isRunning { backgroundDate = Date() }
    }

    func handleForeground() {
        guard let bg = backgroundDate, isRunning else { return }
        let elapsed = Int(Date().timeIntervalSince(bg))
        secondsRemaining = max(0, secondsRemaining - elapsed)
        backgroundDate = nil
        if secondsRemaining == 0 { complete() }
    }

    private func complete() {
        pause()
        if phase == .work {
            if !selectedSubject.isEmpty {
                let session = StudySession(
                    subject: selectedSubject,
                    durationMinutes: 25,
                    isPomodoro: true
                )
                appData?.addSession(session)
            }
            completedPomodoros += 1
            phase = completedPomodoros % 4 == 0 ? .longBreak : .shortBreak
        } else {
            phase = .work
        }
        secondsRemaining = phase.totalSeconds
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "LockedIn"
        content.body = phase == .work
            ? "Focus session done. Time for a break."
            : "Break over. Lock back in."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(secondsRemaining),
            repeats: false
        )
        let req = UNNotificationRequest(identifier: "lockedin_timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}

struct FocusTimerView: View {
    @EnvironmentObject var appData: AppData
    @StateObject private var pom = PomodoroTimer()

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 28) {
                    Picker("Subject", selection: $pom.selectedSubject) {
                        Text("No subject").tag("")
                        ForEach(appData.subjects) { s in
                            Text(s.name).tag(s.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appCard)
                    .cornerRadius(12)
                    .accentColor(Color.appAccent)

                    Text(pom.phase.rawValue)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(pom.phase.color)

                    ZStack {
                        Circle()
                            .stroke(Color.appPrimaryText.opacity(0.12), lineWidth: 14)

                        Circle()
                            .trim(from: 0, to: pom.ringProgress)
                            .stroke(
                                pom.phase.color,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: pom.ringProgress)

                        VStack(spacing: 4) {
                            Text(pom.timeString)
                                .font(.system(size: 60, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.appPrimaryText)
                            Text("\(pom.completedPomodoros) pomodoros today")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                        }
                    }
                    .frame(width: 260, height: 260)

                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { i in
                            Circle()
                                .fill(i < pom.completedPomodoros % 4
                                      ? pom.phase.color
                                      : Color.appPrimaryText.opacity(0.15))
                                .frame(width: 12, height: 12)
                        }
                    }

                    HStack(spacing: 28) {
                        CircleButton(icon: "arrow.counterclockwise", size: 52, action: pom.reset)

                        Button(action: { pom.isRunning ? pom.pause() : pom.start() }) {
                            Image(systemName: pom.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.appAccent)
                                .clipShape(Circle())
                        }

                        CircleButton(icon: "forward.fill", size: 52, action: pom.skip)
                    }
                }
                .padding()
            }
            .navigationTitle("Focus Timer")
            .onAppear { pom.appData = appData }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                pom.handleBackground()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                pom.handleForeground()
            }
        }
    }
}

struct CircleButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.appSecondaryText)
                .frame(width: size, height: size)
                .background(Color.appCard)
                .clipShape(Circle())
        }
    }
}
