import AppKit
import Combine
import SwiftUI

/// First-run setup: Accessibility access, loading the login list, and the shortcut.
struct WelcomeView: View {
    @ObservedObject var model: SearchModel
    @ObservedObject var preferences: Preferences
    /// Brings this window back after Passwords was in front for Touch ID.
    let refocus: () -> Void
    let finish: () -> Void

    @State private var trusted = AXIsProcessTrusted()
    private let poll = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 88, height: 88)
                Text("Welkom bij SnelWachtwoord")
                    .font(.system(size: 24, weight: .semibold))
                Text("Kopieer je favoriete inloggegevens vanuit de menubalk.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                Step(number: 1, title: "Geef toegang via Toegankelijkheid",
                     detail: "SnelWachtwoord leest de app Wachtwoorden op dezelfde manier als een schermlezer.",
                     done: trusted) {
                    Button("Open Systeeminstellingen", action: requestAccess)
                }
                Divider().padding(.leading, 52)
                Step(number: 2, title: "Lees je inloggegevens in",
                     detail: model.logins.isEmpty
                        ? "Ontgrendel Wachtwoorden met Touch ID. SnelWachtwoord bewaart titels en gebruikersnamen lokaal."
                        : "Je kunt nu \(model.logins.count.formatted()) inloggegevens doorzoeken.",
                     done: !model.logins.isEmpty) {
                    Button("Laad inloggegevens") { model.synchronizeFavorites(done: refocus) }
                        .disabled(!trusted || model.busy)
                }
                Divider().padding(.leading, 52)
                Step(number: 3, title: "Druk in elke app op \(preferences.openShortcut.display)",
                     detail: "Kies favorieten met de ster. Synchroniseer ze daarna vanuit het menubalkmenu.",
                     done: false) {
                    EmptyView()
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.4)))

            Button("Aan de slag", action: finish)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .disabled(!trusted || model.logins.isEmpty)
        }
        .padding(32)
        .frame(width: 540)
        .onReceive(poll) { _ in trusted = AXIsProcessTrusted() }
    }

    /// Adds QuickPass to the Accessibility list, then opens that page so it's one switch away.
    private func requestAccess() {
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}

private struct Step<Action: View>: View {
    let number: Int
    let title: String
    let detail: String
    let done: Bool
    @ViewBuilder let action: () -> Action

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().fill(done ? Color.green : Color.accentColor.opacity(0.15))
                if done {
                    Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                } else {
                    Text("\(number)").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.accentColor)
                }
            }
            .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(detail).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            if !done { action() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
