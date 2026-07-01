import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var sectionStore: SectionStore
    @State private var showGuiltScreen = false

    var body: some View {
        ZStack {
            Group {
                switch sectionStore.section {
                case .study:
                    TabView {
                        HomeView()
                            .tabItem { Label("Home",    systemImage: "house.fill") }
                        FocusTimerView()
                            .tabItem { Label("Focus",   systemImage: "timer") }
                        ManualLogView()
                            .tabItem { Label("Log",     systemImage: "square.and.pencil") }
                        HistoryView()
                            .tabItem { Label("History", systemImage: "clock.fill") }
                        GoalsView()
                            .tabItem { Label("Goals",   systemImage: "target") }
                    }
                    .accentColor(Color.appAccent)

                case .diet:
                    TabView {
                        DietView()
                            .tabItem { Label("Today",   systemImage: "fork.knife") }
                        LogFoodView()
                            .tabItem { Label("Log",     systemImage: "plus.circle") }
                        DietHistoryView()
                            .tabItem { Label("History", systemImage: "clock.fill") }
                        DietGoalsView()
                            .tabItem { Label("Goals",   systemImage: "target") }
                    }
                    .accentColor(Color.appAccent)

                case .finance:
                    TabView {
                        FinanceView()
                            .tabItem { Label("Today",   systemImage: "dollarsign.circle.fill") }
                        LogExpenseView()
                            .tabItem { Label("Log",     systemImage: "plus.circle") }
                        FinanceHistoryView()
                            .tabItem { Label("History", systemImage: "clock.fill") }
                        FinanceGoalsView()
                            .tabItem { Label("Goals",   systemImage: "target") }
                    }
                    .accentColor(Color.appAccent)
                }
            }

            if showGuiltScreen {
                GuiltScreenView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showGuiltScreen = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear { checkGuiltScreen() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkGuiltScreen()
        }
    }

    private func checkGuiltScreen() {
        guard appData.totalDailyGoalMinutes > 0 else { return }
        withAnimation(.easeIn(duration: 0.3)) {
            showGuiltScreen = true
        }
    }
}

