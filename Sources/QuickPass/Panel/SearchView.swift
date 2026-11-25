import SwiftUI

struct SearchView: View {
    @ObservedObject var model: SearchModel
    @ObservedObject var preferences: Preferences
    /// Runs a detail view row: Return or a double-click.
    let activate: (DetailItem) -> Void
    let synchronize: () -> Void
    let copyFavorite: (Field, Login) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if model.newLogin != nil {
                NewLoginView(model: model, preferences: preferences)
                statusLine
            } else if model.generatedPassword != nil {
                GeneratorView(model: model, preferences: preferences)
            } else {
                searchField
                statusLine
                if model.detail, let login = model.selectedLogin {
                    DetailView(model: model, preferences: preferences, login: login, activate: activate)
                } else {
                    ResultsList(model: model, preferences: preferences, copyFavorite: copyFavorite)
                }
            }
        }
        .frame(width: 640)
        .modifier(CardBackground())
        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
        .padding(.horizontal, SearchPanel.cardSide)
        .padding(.top, SearchPanel.cardTop)
        .onAppear { focused = true }
        .onChange(of: model.opens) { _, _ in focused = true }
        .onChange(of: model.newLogin == nil) { _, closed in if closed { focused = true } }
        .onChange(of: model.generatedPassword == nil) { _, closed in if closed { focused = true } }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("Zoek in Wachtwoorden", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 22))
                .focused($focused)
            if !model.detail, model.showsFavorites || model.logins.isEmpty {
                Button("Synchroniseer favorieten", action: synchronize)
                    .buttonStyle(.bordered)
                    .disabled(model.busy)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .overlay(alignment: .bottom) { LoadingBar(active: model.busy) }
    }

    @ViewBuilder private var statusLine: some View {
        if let status = model.status {
            Text(status)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
        }
    }
}

/// Liquid Glass needs macOS 26.
private struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: 22))
        } else {
            content.background(.regularMaterial, in: .rect(cornerRadius: 22))
        }
    }
}

private struct ResultsList: View {
    @ObservedObject var model: SearchModel
    @ObservedObject var preferences: Preferences
    let copyFavorite: (Field, Login) -> Void
    private let rowHeight: CGFloat = 50
    private let maxVisibleRows = 7

    private let createRowHeight: CGFloat = 46

    var body: some View {
        let results = model.results
        let showOnlyFavorites = model.showsFavorites
        let hasFooter = !showOnlyFavorites || results.isEmpty
        Divider().padding(.horizontal, 12)
        if showOnlyFavorites {
            HStack {
                Text("Favorieten").fontWeight(.semibold)
                Spacer()
                if !results.isEmpty { Text("Klik voor wachtwoord · Rechtsklik voor gebruikersnaam") }
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .padding(.top, 10)
        }
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.offset) { index, login in
                        resultRow(login, at: index)
                            .frame(height: rowHeight)
                            .id(index)
                    }
                    if !results.isEmpty && hasFooter {
                        Divider().padding(.horizontal, 6).padding(.vertical, 4)
                    }
                    if showOnlyFavorites {
                        if results.isEmpty {
                            Text(model.logins.isEmpty
                                 ? "Synchroniseer om je inloggegevens te laden."
                                 : "Zoek inloggegevens en klik op de ster om ze hier toe te voegen.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .frame(height: createRowHeight)
                        }
                    } else {
                        CreateRow(query: model.query, selected: model.isOnCreateRow)
                            .frame(height: createRowHeight)
                            // Its own kind of id: sharing the rows' numbers made SwiftUI mix it up with a
                            // row whenever the number of results changed.
                            .id(Self.createRowID)
                            .onTapGesture { model.selection = results.count }
                    }
                }
                .padding(6)
            }
            .scrollIndicators(.never)
            .frame(height: CGFloat(min(results.count, maxVisibleRows)) * rowHeight
                + (hasFooter ? createRowHeight : 0) + (!results.isEmpty && hasFooter ? 21 : 12))
            .onAppear { proxy.scrollTo(scrollID(model.selection, of: results)) }
            .onChange(of: model.selection) { _, index in proxy.scrollTo(scrollID(index, of: results)) }
            // A shorter list keeps the old scroll position, which can leave the results above the
            // visible area. Back to the top on every new search.
            .onChange(of: model.query) { _, _ in
                DispatchQueue.main.async { proxy.scrollTo(0, anchor: .top) }
            }
            .onChange(of: model.opens) { _, _ in proxy.scrollTo(scrollID(model.selection, of: results)) }
        }
    }

    private func resultRow(_ login: Login, at index: Int) -> some View {
        let row = LoginRow(login: login, selected: index == model.selection,
                           copied: model.copied[login] ?? [], preferences: preferences)
        let pinned = model.favorites.contains(login)
        let pinLabel = pinned ? "Uit favorieten verwijderen" : "Aan favorieten toevoegen"
        return HStack(spacing: 0) {
            if model.showsFavorites {
                FavoriteButton(login: login, index: index, copy: { copyFavorite($0, login) })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(index == model.selection ? Color.accentColor.opacity(0.22) : .clear))
            } else {
                row.onTapGesture { model.selection = index }
            }
            if pinned || model.canFavorite(login) {
                Button { model.toggleFavorite(login) } label: {
                    Image(systemName: pinned ? "star.fill" : "star")
                        .foregroundStyle(pinned ? Color.accentColor : Color.secondary)
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(model.busy)
                .help(pinLabel)
                .accessibilityLabel(pinLabel)
                .accessibilityIdentifier("favorite-toggle-\(index)")
            }
        }
    }

    private static let createRowID = "create"

    private func scrollID(_ index: Int, of results: [Login]) -> AnyHashable {
        index < results.count ? AnyHashable(index) : AnyHashable(Self.createRowID)
    }
}

private struct FavoriteButton: NSViewRepresentable {
    let login: Login
    let index: Int
    let copy: (Field) -> Void

    func makeNSView(context: Context) -> CopyButton {
        let button = CopyButton()
        button.isBordered = false
        button.alignment = .left
        button.cell?.lineBreakMode = .byTruncatingTail
        button.target = button
        button.action = #selector(CopyButton.copyPassword)
        button.setAccessibilityHelp("Klik om het wachtwoord te kopiëren. Klik met de rechtermuisknop voor de gebruikersnaam.")
        button.setAccessibilityCustomActions([
            NSAccessibilityCustomAction(name: "Gebruikersnaam kopiëren") { [weak button] in
                guard let button else { return false }
                button.copy?(.username)
                return true
            },
        ])
        return button
    }

    func updateNSView(_ button: CopyButton, context: Context) {
        button.title = login.username.isEmpty ? login.title : "\(login.title) · \(login.username)"
        button.setAccessibilityIdentifier("favorite-copy-\(index)")
        button.copy = copy
    }

    final class CopyButton: NSButton {
        var copy: ((Field) -> Void)?

        @objc func copyPassword() { copy?(.password) }

        override func rightMouseDown(with event: NSEvent) {}

        override func rightMouseUp(with event: NSEvent) {
            if bounds.contains(convert(event.locationInWindow, from: nil)) { copy?(.username) }
        }
    }
}

/// The last row of every list: start a new login, named after the search when there is one.
private struct CreateRow: View {
    let query: String
    let selected: Bool

    var body: some View {
        let name = query.trimmingCharacters(in: .whitespaces)
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30)
            Text(name.isEmpty ? "Nieuwe inloggegevens toevoegen" : "Inloggegevens toevoegen voor “\(name)”")
                .font(.system(size: 14))
                .lineLimit(1)
            Spacer(minLength: 8)
            Chip(icon: "plus", label: "⌘N")
        }
        .padding(.horizontal, 10)
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(selected ? Color.accentColor.opacity(0.22) : .clear))
        .contentShape(Rectangle())
    }
}

private struct LoginRow: View {
    let login: Login
    let selected: Bool
    let copied: Set<Field>
    @ObservedObject var preferences: Preferences

    var body: some View {
        HStack(spacing: 12) {
            Monogram(title: login.title, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(login.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                Text(login.username.isEmpty ? "Geen gebruikersnaam" : login.username)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if selected {
                HStack(spacing: 6) {
                    if !login.username.isEmpty { chip(.username) }
                    chip(.password)
                    if login.hasCode { chip(.code) }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(selected ? Color.accentColor.opacity(0.22) : .clear))
        .contentShape(Rectangle())
    }

    private func chip(_ field: Field) -> some View {
        Chip(icon: field.icon, label: preferences.shortcut(for: field)?.display ?? "", done: copied.contains(field))
    }
}

/// A thin animated bar along the bottom of the search field while QuickPass is waiting on Passwords.
struct LoadingBar: View {
    let active: Bool

    var body: some View {
        // The moving bar is only in the view while loading. Hidden with opacity, its endless
        // animation kept SwiftUI redrawing all the time, about 6% CPU with the panel closed.
        ZStack { if active { MovingBar().transition(.opacity) } }
            .frame(height: 2)
            .animation(.easeOut(duration: 0.2), value: active)
    }
}

private struct MovingBar: View {
    @State private var offset: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(Color.accentColor.opacity(0.8))
                .frame(width: geometry.size.width * 0.3, height: 2)
                .offset(x: offset * geometry.size.width)
        }
        .frame(height: 2)
        .clipped()
        .padding(.horizontal, 14)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { offset = 0.7 }
        }
    }
}
