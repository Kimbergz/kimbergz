import Foundation

struct Subject: Codable, Identifiable {
    var id: UUID
    var name: String
    var dailyGoalMinutes: Int
    var colorHex: String

    init(
        id: UUID = UUID(),
        name: String,
        dailyGoalMinutes: Int = 60,
        colorHex: String = "7C5CFC"
    ) {
        self.id = id
        self.name = name
        self.dailyGoalMinutes = dailyGoalMinutes
        self.colorHex = colorHex
    }
}
