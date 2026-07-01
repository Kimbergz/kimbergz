import Foundation

enum FoodFeeling: String, Codable, CaseIterable {
    case great = "Great"
    case fine  = "Fine"
    case meh   = "Meh"
    case gross = "Gross"
}

struct DietEntry: Identifiable, Codable {
    var id       = UUID()
    var date     = Date()
    var foodName : String
    var calories : Double
    var protein  : Double
    var carbs    : Double
    var fats     : Double
    var fiber    : Double
    var feeling  : FoodFeeling
    var guilty   : Bool
    var tasty    : Bool
}
