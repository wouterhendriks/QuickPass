import Foundation

/// The kinds of generated password, the same three 1Password offers.
enum PasswordStyle: Int, Codable {
    /// Random characters at a chosen length.
    case random = 1
    /// Everyday Dutch words joined by the selected separator.
    case memorable = 2
    /// Digits only.
    case pin = 3
}

/// The options for generated passwords. Remembered between uses.
struct PasswordRecipe: Codable, Equatable {
    var style: PasswordStyle = .memorable
    var length = 20
    var uppercase = true
    var numbers = true
    var symbols = true
    var wordCount = 4
    var separator = "-"
    var capitalize = true
    var addNumber = true
    var pinLength = 6
}

enum PasswordGenerator {
    static func make(_ recipe: PasswordRecipe) -> String {
        // SystemRandomNumberGenerator draws from the system's cryptographically secure source.
        var random = SystemRandomNumberGenerator()
        switch recipe.style {
        case .random:
            var kinds = [lowercase]
            if recipe.uppercase { kinds.append(uppercase) }
            if recipe.numbers { kinds.append(digits) }
            if recipe.symbols { kinds.append(symbolSet) }
            // One of each chosen kind first, so strict sign-up rules are always met, then shuffled in.
            let pool = kinds.joined()
            var characters = kinds.map { $0.randomElement(using: &random)! }
            while characters.count < max(recipe.length, kinds.count) { characters.append(pool.randomElement(using: &random)!) }
            return String(characters.shuffled(using: &random))

        case .memorable:
            guard !dictionary.isEmpty else {
                // Missing bundle data must not turn password generation into a predictable phrase.
                var fallback = recipe
                fallback.style = .random
                fallback.length = max(recipe.length, 32)
                return make(fallback)
            }
            var words = (0..<max(recipe.wordCount, 1)).map { _ in
                dictionary[Int.random(in: dictionary.indices, using: &random)]
            }
            if recipe.capitalize { words = words.map { $0.prefix(1).uppercased() + $0.dropFirst() } }
            if recipe.addNumber {
                let index = Int.random(in: words.indices, using: &random)
                words[index] += String(Int.random(in: 0...9, using: &random))
            }
            return words.joined(separator: recipe.separator)

        case .pin:
            return String((0..<max(recipe.pinLength, 1)).map { _ in digits.randomElement(using: &random)! })
        }
    }

    private static let lowercase = "abcdefghijklmnopqrstuvwxyz"
    private static let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private static let digits = "0123456789"
    /// Symbols nearly every site accepts. Leaves out quotes, backslash and spaces, which some reject.
    private static let symbolSet = "!@#$%^&*-_=+?"

    /// Require the full set of unique entries so each draw provides the intended entropy.
    private static let dictionary: [String] = {
        guard let url = Bundle.main.url(forResource: "dutch_diceware", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let words = text.split(whereSeparator: \.isNewline)
            .filter { !$0.hasPrefix("#") }
            .map(String.init)
        guard words.count == 7_776, Set(words).count == words.count,
              words.allSatisfy({ $0.utf8.allSatisfy { (97...122).contains($0) } }) else { return [] }
        return words
    }()
}
