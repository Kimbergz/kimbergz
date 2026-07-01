import SwiftUI

struct DietGoalsView: View {
    @EnvironmentObject var appData: AppData

    @State private var calorieText = ""
    @State private var showBanner  = false
    @FocusState private var fieldFocused: Bool

    private var calorieProgress: Double {
        guard appData.dietDailyCalorieGoal > 0 else { return 0 }
        return min(appData.todayCalories / appData.dietDailyCalorieGoal, 1.0)
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Current goal card
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Daily Calorie Goal",
                                value: appData.dietDailyCalorieGoal > 0
                                    ? "\(Int(appData.dietDailyCalorieGoal))"
                                    : "Not set",
                                icon: "flame.fill",
                                iconColor: Color(hex: "E68523")
                            )
                            StatCard(
                                title: "Today",
                                value: "\(Int(appData.todayCalories))",
                                icon: "fork.knife",
                                iconColor: Color.appAccent
                            )
                        }
                        .padding(.horizontal)

                        // Progress bar
                        if appData.dietDailyCalorieGoal > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Today's progress")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color.appSecondaryText)
                                    Spacer()
                                    Text("\(Int(appData.todayCalories)) / \(Int(appData.dietDailyCalorieGoal)) kcal")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(calorieProgress >= 1 ? Color(hex: "CC1016") : Color.appPrimaryText)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.appPrimaryText.opacity(0.1))
                                            .frame(height: 8)
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(calorieProgress >= 1 ? Color(hex: "CC1016") : Color.appAccent)
                                            .frame(width: geo.size.width * calorieProgress, height: 8)
                                            .animation(.easeOut(duration: 0.5), value: calorieProgress)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding()
                            .background(Color.appCard)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Set goal
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Set daily calorie limit")
                                .font(.headline)
                                .foregroundColor(Color.appPrimaryText)

                            HStack(alignment: .center, spacing: 8) {
                                TextField("e.g. 2000", text: $calorieText)
                                    .keyboardType(.numberPad)
                                    .focused($fieldFocused)
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") { fieldFocused = false }
                                        }
                                    }
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(Color.appPrimaryText)
                                Text("kcal")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color.appSecondaryText)
                            }
                            .padding()
                            .background(Color.appCard)
                            .cornerRadius(14)

                            Text("Typical adult: 1800–2200 kcal/day")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal)

                        Button(action: save) {
                            Text("Save Goal")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appAccent)
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        Spacer(minLength: 60)
                    }
                    .padding(.top)
                }

                if showBanner {
                    Label("Goal saved", systemImage: "checkmark.circle.fill")
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
            .navigationTitle("Diet Goals")
            .onAppear {
                if appData.dietDailyCalorieGoal > 0 {
                    calorieText = "\(Int(appData.dietDailyCalorieGoal))"
                }
            }
        }
    }

    private func save() {
        if let v = Double(calorieText), v > 0 {
            appData.saveDietCalorieGoal(v)
            withAnimation { showBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation { showBanner = false }
            }
        }
    }
}
