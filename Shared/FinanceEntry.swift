import Foundation

struct FinanceEntry: Identifiable, Codable {
    var id          = UUID()
    var date        = Date()
    var amount      : Double
    var label       : String
    var worthIt     : Bool
    var keepIt      : Bool
    var beneficial  : Bool
}
