import SwiftUI

struct LogFoodView: View {
    @EnvironmentObject var appData: AppData

    @State private var foodName  = ""
    @State private var calories  : Double = 300
    @State private var protein   : Double = 20
    @State private var carbs     : Double = 40
    @State private var fats      : Double = 10
    @State private var fiber     : Double = 5
    @State private var feeling   : FoodFeeling = .fine
    @State private var guilty    = false
    @State private var tasty     = true
    @State private var showBanner = false

    var canSave: Bool { !foodName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Food name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What did you eat?")
                                .font(.headline)
                                .foregroundColor(Color.appPrimaryText)
                            TextField("e.g. Chicken breast & rice", text: $foodName)
                                .padding(12)
                                .background(Color.appCard)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Macro sliders
                        VStack(spacing: 0) {
                            MacroSliderRow(label: "Calories", value: $calories,
                                           range: 0...2000, step: 100,
                                           unit: "kcal", color: Color.appAccent)
                            Divider().padding(.leading, 16)
                            MacroSliderRow(label: "Protein",  value: $protein,
                                           range: 0...200,  step: 5,
                                           unit: "g",    color: Color(hex: "057642"))
                            Divider().padding(.leading, 16)
                            MacroSliderRow(label: "Carbs",    value: $carbs,
                                           range: 0...300,  step: 5,
                                           unit: "g",    color: Color(hex: "b24020"))
                            Divider().padding(.leading, 16)
                            MacroSliderRow(label: "Fats",     value: $fats,
                                           range: 0...150,  step: 5,
                                           unit: "g",    color: Color(hex: "a37c00"))
                            Divider().padding(.leading, 16)
                            MacroSliderRow(label: "Fiber",    value: $fiber,
                                           range: 0...80,   step: 1,
                                           unit: "g",    color: Color(hex: "5E5E5E"))
                        }
                        .background(Color.appCard)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // How did it make you feel
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How did it make you feel?")
                                .font(.headline)
                                .foregroundColor(Color.appPrimaryText)
                            HStack(spacing: 8) {
                                ForEach(FoodFeeling.allCases, id: \.self) { f in
                                    Button(f.rawValue) { feeling = f }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(feeling == f ? .white : Color.appPrimaryText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(feeling == f ? Color.appAccent : Color.appBackground)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.appPrimaryText.opacity(0.2), lineWidth: 1))
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding()
                        .background(Color.appCard)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // Guilty + Tasty
                        VStack(spacing: 0) {
                            Toggle(isOn: $guilty) {
                                Label("Did you feel guilty eating this?", systemImage: "face.smiling.inverse")
                                    .font(.subheadline)
                                    .foregroundColor(Color.appPrimaryText)
                            }
                            .tint(Color.appAccent)
                            .padding()
                            Divider()
                            Toggle(isOn: $tasty) {
                                Label("Was it at least good?", systemImage: "hand.thumbsup")
                                    .font(.subheadline)
                                    .foregroundColor(Color.appPrimaryText)
                            }
                            .tint(Color.appAccent)
                            .padding()
                        }
                        .background(Color.appCard)
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // Save
                        Button(action: save) {
                            Text("Log Meal")
                                .font(.headline)
                                .foregroundColor(canSave ? .white : Color.appSecondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canSave ? Color.appAccent : Color.appCard)
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                        .padding(.horizontal)

                        Spacer(minLength: 60)
                    }
                    .padding(.top)
                }

                if showBanner {
                    Label("Meal logged", systemImage: "checkmark.circle.fill")
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
            .navigationTitle("Log Meal")
        }
    }

    private func save() {
        let entry = DietEntry(
            foodName: foodName.trimmingCharacters(in: .whitespaces),
            calories: calories,
            protein:  protein,
            carbs:    carbs,
            fats:     fats,
            fiber:    fiber,
            feeling:  feeling,
            guilty:   guilty,
            tasty:    tasty
        )
        appData.addDietEntry(entry)
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showBanner = false }
        }
        resetForm()
    }

    private func resetForm() {
        foodName = ""
        calories = 300
        protein  = 20
        carbs    = 40
        fats     = 10
        fiber    = 5
        feeling  = .fine
        guilty   = false
        tasty    = true
    }
}

struct MacroSliderRow: View {
    let label : String
    @Binding var value: Double
    let range : ClosedRange<Double>
    let step  : Double
    let unit  : String
    let color : Color

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.appPrimaryText)
                Spacer()
                Text(value < 10 ? String(format: "%.1f \(unit)", value) : "\(Int(value)) \(unit)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(color)
                    .frame(minWidth: 70, alignment: .trailing)
            }
            Slider(value: $value, in: range, step: step)
                .accentColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
