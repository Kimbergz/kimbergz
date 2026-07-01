import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy      = "Light"
    case moderate  = "Easy"
    case hard      = "Meh"
    case veryHard  = "Hard"
    case brutal    = "Fuck."
}

struct StudySession: Codable, Identifiable {
    var id: UUID
    var subject: String
    var durationMinutes: Int
    var difficulty: Difficulty?
    var date: Date
    var isPomodoro: Bool

    init(
        id: UUID = UUID(),
        subject: String,
        durationMinutes: Int,
        difficulty: Difficulty? = nil,
        date: Date = Date(),
        isPomodoro: Bool = false
    ) {
        self.id = id
        self.subject = subject
        self.durationMinutes = durationMinutes
        self.difficulty = difficulty
        self.date = date
        self.isPomodoro = isPomodoro
    }
}
