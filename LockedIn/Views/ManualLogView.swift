import SwiftUI

struct ManualLogView: View {
    @EnvironmentObject var appData: AppData

    @State private var subject    = ""
    @State private var hours      = 0
    @State private var minutes    = 30
    @State private var difficulty: Difficulty? = nil
    @State private var date       = Date()
    @State private var showBanner = false

    var totalMinutes: Int { hours * 60 + minutes }
    var canLog: Bool { !subject.isEmpty && totalMinutes > 0 && difficulty != nil }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                Form {
                    Section("Subject") {
                        if appData.subjects.isEmpty {
                            Text("Add subjects in the Goals tab first")
                                .foregroundColor(Color.appSecondaryText)
                        } else {
                            Picker("Subject", selection: $subject) {
                                Text("Choose…").tag("")
                                ForEach(appData.subjects) { s in
                                    Text(s.name).tag(s.name)
                                }
                            }
                        }
                    }

                    Section("Duration") {
                        Stepper("Hours: \(hours)", value: $hours, in: 0...12)
                        Stepper("Minutes: \(minutes)", value: $minutes, in: 0...55, step: 5)
                        Text("Total: \(formatMinutes(totalMinutes))")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    }

                    Section("Difficulty") {
                        HStack(spacing: 8) {
                            ForEach(Difficulty.allCases, id: \.self) { level in
                                DifficultyButton(
                                    label: level.rawValue,
                                    isSelected: difficulty == level
                                ) {
                                    difficulty = level
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    Section("Date") {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                    }

                    Section {
                        Button(action: logSession) {
                            Text("Save Session")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                        }
                        .disabled(!canLog)
                        .foregroundColor(canLog ? Color.appAccent : Color.appSecondaryText)
                    }
                }
                .scrollContentBackground(.hidden)
                .onAppear {
                    if subject.isEmpty, let first = appData.subjects.first {
                        subject = first.name
                    }
                }

                if showBanner {
                    Label("Session saved", systemImage: "checkmark.circle.fill")
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
            .navigationTitle("Log Session")
        }
    }

    func logSession() {
        appData.addSession(StudySession(
            subject: subject,
            durationMinutes: totalMinutes,
            difficulty: difficulty,
            date: date
        ))
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showBanner = false }
        }
        hours      = 0
        minutes    = 30
        difficulty = nil
        date       = Date()
    }
}

struct DifficultyButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.appPrimaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.appAccent : Color.appCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.appAccent : Color.appPrimaryText.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
