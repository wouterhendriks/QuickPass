/* swiftc Sources/QuickPass/App/SearchModel.swift Sources/QuickPass/Passwords/{FavoritePasswordStore,Login,PasswordGenerator,PasswordsApp}.swift Sources/QuickPass/Settings/{Preferences,Shortcut}.swift Sources/QuickPass/System/Keyboard.swift Tests/FavoriteSyncTests.swift -o /tmp/snelwachtwoord-sync-tests && /tmp/snelwachtwoord-sync-tests */
import AppKit

private final class TestPasswords: PasswordsApp {
    static let favorite = Login(title: "Fictional example", username: "test@example.com", index: 1, hasCode: false)
    static let other = Login(title: "Another example", username: "other@example.com", index: 0, hasCode: false)
    private let lock = NSLock()
    private var readCount = 0
    private var requested: [Login] = []
    private var secret: String? = "fictional-password-one"

    var reads: Int { lock.withLock { readCount } }
    var requests: [Login] { lock.withLock { requested } }

    override var isRunning: Bool { true }

    func changePassword(to secret: String?) { lock.withLock { self.secret = secret } }

    override func loadLogins(fillBlanks: Bool) -> [Login]? {
        lock.withLock { readCount += 1 }
        return [Self.other, Self.favorite]
    }

    override func logins(from start: Int, max: Int, fillBlanks: Bool) -> (logins: [Login], total: Int)? {
        lock.withLock { readCount += 1 }
        return nil
    }

    override func favoritePassword(for login: Login) throws -> String? {
        try lock.withLock {
            requested.append(login)
            guard let secret else { throw PasswordsError.copyFailed }
            return secret
        }
    }
}

@main
struct FavoriteSyncTests {
    @MainActor static func main() async throws {
        let passwords = TestPasswords()
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.clearContents()
        try require(pasteboard.setString("pasteboard-probe", forType: .string)
                    && pasteboard.string(forType: .string) == "pasteboard-probe", "The isolated test pasteboard is unavailable")
        let model = SearchModel(preferences: .shared, passwords: passwords, persists: false, pasteboard: pasteboard)
        let favorite = TestPasswords.favorite
        model.willOpen(showFavorites: true)
        model.didClose()
        try await Task.sleep(for: .milliseconds(300))
        try require(passwords.reads == 0, "Browsing favorites contacted Apple Passwords")

        await withCheckedContinuation { continuation in model.synchronizeFavorites { continuation.resume() } }
        try require(model.logins.count == 2 && passwords.requests.isEmpty, "Initial sync fetched unpinned passwords")
        model.toggleFavorite(favorite)
        let missingBeforeSync = await withCheckedContinuation { continuation in
            model.copy(.password, for: favorite) { continuation.resume(returning: $0) }
        }
        try require(!missingBeforeSync && passwords.requests.isEmpty, "Copy looked up an unsynchronized favorite")

        await withCheckedContinuation { continuation in model.synchronizeFavorites { continuation.resume() } }
        try require(passwords.requests == [favorite], "Sync fetched a password outside the favorites")
        let copied = await withCheckedContinuation { continuation in
            model.copy(.password, for: favorite) { continuation.resume(returning: $0) }
        }
        try require(copied && pasteboard.string(forType: .string) == "fictional-password-one", "Wrong favorite password on clipboard")
        try require(passwords.requests == [favorite] && passwords.reads == 2, "Copy contacted Apple Passwords")
        let usernameCopied = await withCheckedContinuation { continuation in
            model.copy(.username, for: favorite) { continuation.resume(returning: $0) }
        }
        try require(usernameCopied && pasteboard.string(forType: .string) == "test@example.com", "Wrong username on clipboard")

        passwords.changePassword(to: nil)
        await withCheckedContinuation { continuation in model.synchronizeFavorites { continuation.resume() } }
        let copiedAfterFailure = await withCheckedContinuation { continuation in
            model.copy(.password, for: favorite) { continuation.resume(returning: $0) }
        }
        try require(copiedAfterFailure && pasteboard.string(forType: .string) == "fictional-password-one", "Failed sync overwrote the old snapshot")

        passwords.changePassword(to: "fictional-password-two")
        await withCheckedContinuation { continuation in model.synchronizeFavorites { continuation.resume() } }
        let copiedAfterSync = await withCheckedContinuation { continuation in
            model.copy(.password, for: favorite) { continuation.resume(returning: $0) }
        }
        try require(copiedAfterSync && pasteboard.string(forType: .string) == "fictional-password-two", "Resync did not replace the old password")

        model.toggleFavorite(favorite)
        while model.busy { try await Task.sleep(for: .milliseconds(10)) }
        model.toggleFavorite(favorite)
        let copiedAfterRepin = await withCheckedContinuation { continuation in
            model.copy(.password, for: favorite) { continuation.resume(returning: $0) }
        }
        try require(!copiedAfterRepin, "Removing a favorite left a password behind")

        await withCheckedContinuation { continuation in model.synchronizeFavorites { continuation.resume() } }
        let erased = await withCheckedContinuation { continuation in
            model.eraseFavoritePasswords { continuation.resume(returning: $0) }
        }
        let copiedAfterErasing = await withCheckedContinuation { continuation in
            model.copy(.password, for: favorite) { continuation.resume(returning: $0) }
        }
        try require(erased && !copiedAfterErasing && model.favorites == [favorite], "Erasing local copies changed favorites or kept a password")
        print("Favorite sync, clipboard and erasure checks passed.")
    }

    private static func require(_ condition: Bool, _ message: String) throws {
        guard condition else { throw TestFailure(message: message) }
    }
}

private struct TestFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
