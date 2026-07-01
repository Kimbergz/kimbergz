import SwiftUI

extension Color {
    static let appBackground   = Color(hex: "fdfaf5")
    static let appCard         = Color(hex: "e9e5df")
    static let appAccent       = Color(hex: "0a66c2")
    static let appPrimaryText  = Color(hex: "004182")
    static let appSecondaryText = Color(hex: "5E5E5E")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

func formatMinutes(_ mins: Int) -> String {
    let h = mins / 60
    let m = mins % 60
    if h > 0 && m > 0 { return "\(h)h \(m)m" }
    if h > 0            { return "\(h)h" }
    return "\(m)m"
}
