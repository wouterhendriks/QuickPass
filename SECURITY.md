# Security Policy

## Reporting a vulnerability

Report security problems privately through the GitHub **Security** tab.

## Data handling

| Data | Where it lives |
| --- | --- |
| Login titles and usernames | Local cache at `~/Library/Application Support/nl.webwerf.snelwachtwoord/logins.json` |
| Favorite login references and usage counts | Local preferences |
| Synchronized favorite passwords | One local macOS Keychain item named SnelWachtwoord, accessible to the creating app through the keychain's access controls |
| Other retrieved passwords and verification codes | App memory and the clipboard when copied |
| New logins | Saved to Apple Passwords when requested |

Synchronization reads favorite passwords directly from Apple Passwords without using the clipboard and replaces the local Keychain item only after a successful read. The item does not sync through iCloud. A successful synchronization may omit a favorite whose original entry is missing, ambiguous, or unavailable through Accessibility. Unpinning a favorite removes its local password, and **Lokale kopieën wissen** deletes the item. The first local password copy after app launch, manual lock, or screen lock requires macOS authentication.

Copied login fields stay on the current Mac. Copied passwords and codes are marked as concealed for compatible clipboard managers, and clear from the clipboard after 60 seconds by default if the clipboard still contains that copy. Other apps with clipboard access can read it while it is there.

SnelWachtwoord can fill a login into the previous app when requested with a keyboard shortcut. Saving a new login uses Apple Passwords' New Password form. The app uses the macOS clipboard to fill its password field and then restores the earlier clipboard contents.

## Network access

SnelWachtwoord makes no automatic network requests. Opening a login's website is an explicit action that opens the site in the default browser. Apple Passwords manages its own iCloud synchronization separately.
