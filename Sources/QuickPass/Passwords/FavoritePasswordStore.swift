import Foundation
import Security

/// Keeps all synchronized passwords in one local item, scoped to the app's code signature by Keychain.
/// Only the model's serial Passwords queue calls this store.
final class FavoritePasswordStore {
    private let inMemory: Bool
    private let keychain: SecKeychain?
    private var temporary: [Login: String] = [:]

    init(inMemory: Bool = false, keychain: SecKeychain? = nil) {
        self.inMemory = inMemory
        self.keychain = keychain
    }

    func read() throws -> [Login: String] {
        if inMemory { return temporary }
        var query = itemQuery(for: try localKeychain())
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [:] }
        try check(status)
        guard let data = result as? Data else { throw StoreError.status(errSecDecode) }
        return try JSONDecoder().decode([Login: String].self, from: data)
    }

    func replace(with passwords: [Login: String]) throws {
        if inMemory { temporary = passwords; return }
        let keychain = try localKeychain()
        let query = itemQuery(for: keychain)
        if passwords.isEmpty {
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecItemNotFound { try check(status) }
            return
        }

        let values = [kSecValueData as String: try JSONEncoder().encode(passwords)]
        let updateStatus = SecItemUpdate(query as CFDictionary, values as CFDictionary)
        if updateStatus != errSecItemNotFound { try check(updateStatus); return }

        var item = query
        item.removeValue(forKey: kSecMatchSearchList as String)
        item[kSecUseKeychain as String] = keychain
        item[kSecAttrLabel as String] = "SnelWachtwoord"
        item.merge(values) { _, new in new }
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            try check(SecItemUpdate(query as CFDictionary, values as CFDictionary))
        } else {
            try check(addStatus)
        }
    }

    private func itemQuery(for keychain: SecKeychain) -> [String: Any] {
        // Use the local file-based keychain and its creator ACL, without iCloud or a shared access group.
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "nl.webwerf.snelwachtwoord",
         kSecAttrAccount as String: "favorite-passwords",
         kSecUseDataProtectionKeychain as String: false,
         kSecMatchSearchList as String: [keychain]]
    }

    private func localKeychain() throws -> SecKeychain {
        if let keychain { return keychain }
        var result: SecKeychain?
        try check(SecKeychainCopyDomainDefault(.user, &result))
        guard let result else { throw StoreError.status(errSecNoDefaultKeychain) }
        return result
    }

    private func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else { throw StoreError.status(status) }
    }

    private enum StoreError: Error { case status(OSStatus) }
}
