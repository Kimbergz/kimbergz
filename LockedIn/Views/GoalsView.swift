import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var appData: AppData
    @State private var showAddSheet  = false
    @State private var editSubject: Subject?

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if appData.subjects.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "target")
                            .font(.system(size: 52))
                            .foregroundColor(Color.appSecondaryText.opacity(0.4))
                        Text("No subjects yet")
                            .foregroundColor(Color.appSecondaryText)
                        Button("Add your first subject") { showAddSheet = true }
                            .foregroundColor(Color.appAccent)
                    }
                } else {
                    List {
                        ForEach(appData.subjects) { subject in
                            SubjectGoalRow(subject: subject)
                                .listRowBackground(Color.appCard)
                                .contentShape(Rectangle())
                                .onTapGesture { editSubject = subject }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            appData.deleteSubject(id: subject.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.appAccent)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                SubjectFormSheet(mode: .add)
            }
            .sheet(item: $editSubject) { subject in
                SubjectFormSheet(mode: .edit(subject))
            }
        }
    }
}

struct SubjectGoalRow: View {
    let subject: Subject

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: subject.colorHex))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                    .foregroundColor(Color.appPrimaryText)
                    .font(.subheadline.weight(.semibold))
                Text("Goal: \(formatMinutes(subject.dailyGoalMinutes)) / day")
                    .font(.caption)
                    .foregroundColor(Color.appSecondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color.appSecondaryText)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

enum SubjectFormMode {
    case add
    case edit(Subject)
}

struct SubjectFormSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appData: AppData

    let mode: SubjectFormMode

    @State private var name:        String = ""
    @State private var goalMinutes: Int    = 60
    @State private var colorHex:    String = "0a66c2"

    private let presetColors = [
        "0a66c2", "004182", "057642", "B24020",
        "E68523", "8F5FE8", "CC1016", "00A0B0"
    ]

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Form {
                    Section("Subject Name") {
                        TextField("e.g. Mathematics", text: $name)
                            .foregroundColor(Color.appPrimaryText)
                    }
                    Section("Daily Goal") {
                        Stepper(
                            "\(goalMinutes) minutes (\(formatMinutes(goalMinutes)))",
                            value: $goalMinutes, in: 5...480, step: 5
                        )
                    }
                    Section("Colour") {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 4),
                            spacing: 14
                        ) {
                            ForEach(presetColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.appPrimaryText, lineWidth: colorHex == hex ? 3 : 0)
                                    )
                                    .onTapGesture { colorHex = hex }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEdit ? "Edit Subject" : "New Subject")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.appSecondaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEdit ? "Save" : "Add") { save() }
                        .foregroundColor(Color.appAccent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadInitialValues() }
        }
    }

    private func loadInitialValues() {
        if case .edit(let s) = mode {
            name        = s.name
            goalMinutes = s.dailyGoalMinutes
            colorHex    = s.colorHex
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        switch mode {
        case .add:
            appData.addSubject(Subject(name: trimmed, dailyGoalMinutes: goalMinutes, colorHex: colorHex))
        case .edit(let original):
            var updated = original
            updated.name             = trimmed
            updated.dailyGoalMinutes = goalMinutes
            updated.colorHex         = colorHex
            appData.updateSubject(updated)
        }
        dismiss()
    }
}
