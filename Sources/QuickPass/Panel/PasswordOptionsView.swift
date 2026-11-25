import SwiftUI

/// Compact options for generated passwords, shown wherever a password is made. Choices are
/// remembered. Changing one calls changed, so the caller can make a new password.
struct PasswordOptionsView: View {
    @ObservedObject var preferences: Preferences
    let changed: () -> Void

    private var recipe: Binding<PasswordRecipe> { $preferences.passwordRecipe }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Picker("Type", selection: recipe.style) {
                    Text("Willekeurig").tag(PasswordStyle.random)
                    Text("Wachtwoordzin").tag(PasswordStyle.memorable)
                    Text("Pincode").tag(PasswordStyle.pin)
                }
                .fixedSize()
                switch preferences.passwordRecipe.style {
                case .random: slider("Tekens", value: recipe.length, in: 8...64)
                case .memorable: slider("Woorden", value: recipe.wordCount, in: 3...10)
                case .pin: slider("Cijfers", value: recipe.pinLength, in: 4...12)
                }
            }
            switch preferences.passwordRecipe.style {
            case .random:
                HStack(spacing: 16) {
                    Toggle("Hoofdletters", isOn: recipe.uppercase)
                    Toggle("Cijfers", isOn: recipe.numbers)
                    Toggle("Symbolen", isOn: recipe.symbols)
                }
            case .memorable:
                HStack(spacing: 16) {
                    Toggle("Hoofdletters", isOn: recipe.capitalize)
                    Toggle("Cijfer toevoegen", isOn: recipe.addNumber)
                    Picker("Scheidingsteken", selection: recipe.separator) {
                        Text("Koppelteken").tag("-")
                        Text("Punt").tag(".")
                        Text("Onderstrepingsteken").tag("_")
                        Text("Spatie").tag(" ")
                    }
                    .fixedSize()
                }
            case .pin:
                EmptyView()
            }
        }
        .toggleStyle(.checkbox)
        .controlSize(.small)
        .font(.system(size: 12))
        .onChange(of: preferences.passwordRecipe) { _, _ in changed() }
    }

    private func slider(_ label: String, value: Binding<Int>, in range: ClosedRange<Int>) -> some View {
        HStack(spacing: 8) {
            Text(label).foregroundStyle(.secondary)
            Slider(value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Int($0) }),
                   in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                .accessibilityLabel(label)
            Text("\(value.wrappedValue)").monospacedDigit().frame(width: 22, alignment: .trailing)
        }
    }
}
