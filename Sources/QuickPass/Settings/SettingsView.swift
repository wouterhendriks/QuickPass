import AppKit
import Carbon
import SwiftUI

/// The Settings window: a page per toolbar icon, the standard Mac layout. The window takes each
/// page's size and title.
final class SettingsWindow {
    private var window: NSWindow?
    private let preferences: Preferences
    private let model: SearchModel

    init(preferences: Preferences, model: SearchModel) {
        self.preferences = preferences
        self.model = model
    }

    func show() {
        if window == nil {
            let tabs = NSTabViewController()
            tabs.tabStyle = .toolbar
            let pages: [(String, String, AnyView)] = [
                ("Algemeen", "gearshape", AnyView(GeneralSettings(preferences: preferences))),
                ("Sneltoetsen", "command", AnyView(ShortcutSettings(preferences: preferences))),
                ("Privacy", "hand.raised", AnyView(PrivacySettings(preferences: preferences, model: model))),
            ]
            for (title, icon, view) in pages {
                let host = NSHostingController(rootView: view)
                host.sizingOptions = .preferredContentSize
                host.title = title // the window shows the selected page's title
                let item = NSTabViewItem(viewController: host)
                item.label = title
                item.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
                tabs.addTabViewItem(item)
            }
            let window = NSWindow(contentViewController: tabs)
            window.styleMask = [.titled, .closable]
            window.toolbarStyle = .preference
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
    }
}

private struct GeneralSettings: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section {
                Toggle("Open bij inloggen", isOn: Binding(get: { preferences.launchAtLogin },
                                                        set: { preferences.launchAtLogin = $0 }))
                Toggle("Toon in menubalk", isOn: $preferences.showMenuBarIcon)
            } footer: {
                if !preferences.showMenuBarIcon {
                    Text("Open SnelWachtwoord opnieuw via Spotlight om hier terug te komen.")
                }
            }

        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(width: 480, height: 126)
    }
}

private struct PrivacySettings: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var model: SearchModel
    @State private var confirmErasure = false
    @State private var erasureMessage: String?

    var body: some View {
        Form {
            Section {
                Picker("Wachtwoorden van klembord wissen", selection: $preferences.clearClipboardAfter) {
                    Text("Na 30 seconden").tag(30)
                    Text("Na 1 minuut").tag(60)
                    Text("Na 90 seconden").tag(90)
                    Text("Nooit").tag(0)
                }
                Picker("Zoekopdracht en wachtwoorden onthouden", selection: $preferences.rememberSearchFor) {
                    Text("Uit").tag(0)
                    Text("30 seconden").tag(30)
                    Text("2 minuten").tag(120)
                    Text("5 minuten").tag(300)
                }
            }
            Section {
                Button("Lokale kopieën wissen…", role: .destructive) { confirmErasure = true }
                    .disabled(model.busy)
            } footer: {
                if let erasureMessage { Text(erasureMessage) }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(width: 480, height: 190)
        .confirmationDialog("Lokale wachtwoordkopieën wissen?", isPresented: $confirmErasure, titleVisibility: .visible) {
            Button("Wis lokale kopieën", role: .destructive) {
                model.eraseFavoritePasswords { erased in
                    erasureMessage = erased ? "Lokale kopieën gewist." : "De lokale kopieën konden niet worden gewist."
                }
            }
        } message: {
            Text("Synchroniseer opnieuw om wachtwoorden uit je favorietenmenu te kopiëren.")
        }
    }
}

private struct ShortcutSettings: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section {
                ShortcutRow(title: "SnelWachtwoord openen", shortcut: $preferences.openShortcut, defaultShortcut: .open,
                            preferences: preferences)
                if preferences.openShortcutTaken {
                    Text("Deze sneltoets is al in gebruik. Kies een andere.")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            Section("In de zoekbalk") {
                ShortcutRow(title: "Gebruikersnaam kopiëren", shortcut: $preferences.copyUsernameShortcut, defaultShortcut: .copyUsername,
                            preferences: preferences)
                ShortcutRow(title: "Wachtwoord kopiëren", shortcut: $preferences.copyPasswordShortcut, defaultShortcut: .copyPassword,
                            preferences: preferences)
                ShortcutRow(title: "Verificatiecode kopiëren", shortcut: $preferences.copyCodeShortcut, defaultShortcut: .copyCode,
                            preferences: preferences)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(width: 480, height: 270)
    }
}

private struct ShortcutRow: View {
    let title: String
    @Binding var shortcut: Shortcut
    let defaultShortcut: Shortcut
    @ObservedObject var preferences: Preferences

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                if shortcut != defaultShortcut {
                    Button {
                        shortcut = defaultShortcut
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Stel \(defaultShortcut.display) weer in")
                }
                ShortcutRecorder(shortcut: $shortcut, preferences: preferences)
            }
        }
    }
}

/// Click, then press the new shortcut. Escape cancels.
private struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut
    @ObservedObject var preferences: Preferences
    @State private var monitor: Any?

    private var recording: Bool { monitor != nil }

    var body: some View {
        Button(recording ? "Druk op een sneltoets" : shortcut.display) {
            recording ? stop() : start()
        }
        .frame(minWidth: 110)
        .onDisappear(perform: stop)
    }

    private func start() {
        preferences.isRecordingShortcut = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == kVK_Escape {
                stop()
            } else if let recorded = Shortcut(event: event) {
                shortcut = recorded
                stop()
            }
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        preferences.isRecordingShortcut = false
    }
}
