import Foundation
import SwiftUI

enum AppSection: String, CaseIterable {
    case study   = "Study"
    case diet    = "Diet"
    case finance = "Finance"

    var icon: String {
        switch self {
        case .study:   return "book.fill"
        case .diet:    return "fork.knife"
        case .finance: return "dollarsign.circle.fill"
        }
    }
}

class SectionStore: ObservableObject {
    @Published var section: AppSection = .study
}

struct SectionMenuButton: View {
    @EnvironmentObject var sectionStore: SectionStore

    var body: some View {
        Menu {
            ForEach(AppSection.allCases, id: \.self) { s in
                Button {
                    sectionStore.section = s
                } label: {
                    Label(s.rawValue, systemImage: s.icon)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title3)
                .foregroundColor(Color.appAccent)
        }
    }
}
