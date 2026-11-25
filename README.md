# SnelWachtwoord

Quick access to favorites from Apple Passwords on macOS. This fork is based on [QuickPass by JK Creative Studios](https://github.com/jessekhach/QuickPass).

## Using the menu bar

1. Open the key icon in the menu bar.
2. Search for a login and click its star. Clear the search to see your favorites.
3. Click **Synchroniseer favorieten** to update the local Keychain copy. Use it again after changing a password or adding a favorite.
4. Click a favorite to copy its password. Right-click it to copy its username or email address.

Use **Synchroniseer favorieten** to load the login list on first use. Copying a synchronized favorite works with Apple Passwords closed. SnelWachtwoord asks macOS to authenticate the first favorite password copy after starting or locking. In **Instellingen → Privacy**, **Lokale kopieën wissen** clears the Keychain copy while keeping your favorites pinned.

Press ⌃⌥Space to open the full search panel. Actions such as editing or opening a login still use Apple Passwords, which handles its own unlocking.

## Fork changes (2026-11-24)

This fork adds menu bar favorites, removes automatic updates and website icon downloads, and drops the browser automation permission. The local app has its own bundle identifier and its own cache directory. The build makes a local app bundle without installing or launching it.

See [SECURITY.md](SECURITY.md) for details on local data and the clipboard. A macOS update that changes the Passwords interface may break this integration.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| ⌃⌥Space | Open or close SnelWachtwoord |
| ↑ ↓ | Select a login |
| ⌘C | Copy username |
| ⇧⌘C | Copy password |
| ⌥⌘C | Copy verification code |
| → | Show login details (← to go back) |
| ⌘O | Open the website |
| ⌘↩ | Fill username and password in the previous app |
| ⌥⌘↩ | Fill the verification code in the previous app |
| ⇧⌘O | Open the login in Passwords |
| ⌘⌫ | Delete the login (in details, confirmed with Return) |
| ⌘N | New login |
| ⌘G | Generate a password |
| ⌘, | Settings |
| Esc | Close |

All shortcuts for opening SnelWachtwoord and copying fields can be changed in Settings.

## Building from source

Requires macOS 15 or later, Xcode 26 or later, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
git clone https://github.com/wouterhendriks/QuickPass.git
cd QuickPass
./build.sh
```

The script prints the path to the locally signed app. On first launch, grant it Accessibility access in System Settings and unlock Apple Passwords. Use the same certificate to sign each installed build so macOS can recognize the app's Accessibility grant and local Keychain access across updates. Ad hoc signing ties that identity to one build.

## License

SnelWachtwoord is released under the [GNU General Public License v3.0](LICENSE): you can use, change and share it, and any copy you share has to stay open source under the same license.

The passphrase generator uses [Remko Tronçon’s Dutch Diceware list](https://github.com/remko/password-generator/blob/master/lists/diceware/diceware-wordlist-nl.txt), derived from [Stichting OpenTaal’s word list](https://github.com/OpenTaal/opentaal-wordlist). The app bundles the original words in one-word-per-line format with the attribution and license in [the resource file](Resources/dutch_diceware.txt).
