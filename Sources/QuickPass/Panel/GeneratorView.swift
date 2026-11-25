import SwiftUI

/// ⌘G: a password with its options. Return copies it, Esc goes back.
struct GeneratorView: View {
    @ObservedObject var model: SearchModel
    @ObservedObject var preferences: Preferences

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text("Nieuw wachtwoord").font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            Divider().padding(.horizontal, 12)

            HStack(spacing: 10) {
                Text(model.generatedPassword ?? "")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 8)
                Button(action: model.regenerate) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Ander wachtwoord genereren")
                .help("Ander wachtwoord (⌘G)")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)

            PasswordOptionsView(preferences: preferences, changed: model.regenerate)
                .padding(.horizontal, 18)

            HStack(spacing: 8) {
                Spacer()
                Chip(icon: "arrow.clockwise", label: "⌘G")
                Chip(icon: "escape", label: "Terug")
                Chip(icon: "return", label: "Kopiëren")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
    }
}
