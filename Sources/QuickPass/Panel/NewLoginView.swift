import SwiftUI

/// The form for saving a new login into Passwords. Return saves, Esc goes back to the list.
struct NewLoginView: View {
    @ObservedObject var model: SearchModel
    @ObservedObject var preferences: Preferences
    @FocusState private var focus: Input?

    private enum Input { case title, website, username, password }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text("Nieuwe inloggegevens").font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .overlay(alignment: .bottom) { LoadingBar(active: model.busy) }
            Divider().padding(.horizontal, 12)

            VStack(spacing: 10) {
                row("Titel", icon: "textformat") {
                    TextField("Naam in Wachtwoorden", text: binding(\.title)).focused($focus, equals: .title)
                }
                row("Website", icon: "globe") {
                    TextField("voorbeeld.example", text: binding(\.website)).focused($focus, equals: .website)
                }
                row("Gebruikersnaam of e-mailadres", icon: "person.fill") {
                    TextField("naam@voorbeeld.example", text: binding(\.username)).focused($focus, equals: .username)
                }
                row("Wachtwoord", icon: "key.fill") {
                    HStack {
                        TextField("", text: binding(\.password))
                            .font(.system(size: 15, design: .monospaced))
                            .accessibilityLabel("Wachtwoord")
                            .focused($focus, equals: .password)
                        Button(action: model.regenerate) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Ander wachtwoord genereren")
                        .help("Nieuw wachtwoord (⌘G)")
                    }
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 15))
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            PasswordOptionsView(preferences: preferences, changed: model.regenerate)
                .padding(.horizontal, 18)
                .padding(.bottom, 4)

            HStack(spacing: 8) {
                Spacer()
                Chip(icon: "arrow.clockwise", label: "⌘G")
                Chip(icon: "escape", label: "Annuleren")
                Chip(icon: "return", label: "Bewaren")
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
        }
        // Focus has to wait until the fields exist, a beat after the form appears.
        .task {
            try? await Task.sleep(for: .milliseconds(50))
            let login = model.newLogin
            focus = (login?.website.isEmpty ?? true) ? .website : (login?.title.isEmpty ?? true) ? .title : .username
        }
    }

    private func row<Content: View>(_ label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                content()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.5)))
    }

    private func binding(_ keyPath: WritableKeyPath<NewLogin, String>) -> Binding<String> {
        Binding(get: { model.newLogin?[keyPath: keyPath] ?? "" },
                set: { model.newLogin?[keyPath: keyPath] = $0 })
    }
}
