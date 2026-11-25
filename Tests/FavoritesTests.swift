/* swiftc Sources/QuickPass/Passwords/Login.swift Tests/FavoritesTests.swift -o /tmp/quickpass-favorites-tests && /tmp/quickpass-favorites-tests */
import Foundation

@main
struct FavoritesTests {
    static func main() throws {
        let pinned = Login(title: "Example", username: "alice@example.com", index: 8, hasCode: false)
        let other = Login(title: "Example", username: "bob@example.com", index: 2, hasCode: false)
        var moved = pinned
        moved.index = 3
        moved.hasCode = true
        assert(Login.favorites(in: [other, moved], pinned: [pinned]).map(\.index) == [3])
        assert(Login.favorites(in: [other], pinned: [pinned]).isEmpty)

        var duplicate = moved
        duplicate.copy = 1
        assert(Login.favorites(in: [moved, other, duplicate], pinned: [pinned]).isEmpty)

        let encoded = try JSONEncoder().encode(Set([pinned, other]))
        let decoded = try JSONDecoder().decode(Set<Login>.self, from: encoded)
        assert(Login.favorites(in: [other, moved], pinned: decoded).map(\.index) == [2, 3])

    }
}
