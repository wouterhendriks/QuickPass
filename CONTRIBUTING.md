# Contributing

Bug reports and pull requests are welcome.

## Building

1. Install Xcode 26 or later and XcodeGen: `brew install xcodegen`
2. Run `./build.sh` to build the ad hoc signed app. macOS may ask you to grant Accessibility access again after rebuilding.

The Xcode project is generated from `project.yml`. Make project changes there rather than in `SnelWachtwoord.xcodeproj`.

## Demo mode

Debug builds launched with `-demo` show made-up logins and never touch the Passwords app or SnelWachtwoord's saved files.

```bash
xcodebuild -project SnelWachtwoord.xcodeproj -scheme SnelWachtwoord -configuration Debug -derivedDataPath build/DerivedDataDebug build
open -n build/DerivedDataDebug/Build/Products/Debug/SnelWachtwoord.app --args -demo
```

Quit any other copy of SnelWachtwoord first, since both register the same shortcut.

## Project structure

```
Sources/QuickPass
├── App        app lifecycle, keyboard handling, search state, welcome window
├── Panel      search bar, login details, new-login form, password generator
├── Passwords  Passwords app integration, login model, password generator
├── Settings   preferences, shortcuts, Settings window
└── System     global shortcut, typing, menu bar icon
```

## After a macOS update

Most breakage will be in `Passwords/PasswordsApp.swift`, which drives the Passwords app through Accessibility. SnelWachtwoord finds elements by their accessibility identifiers and menu shortcuts rather than by visible text, so it works in any language. Accessibility Inspector (Xcode › Open Developer Tool) shows the identifiers it relies on:

| Area | Identifiers |
| --- | --- |
| Sidebar | `AllTile`, `CodesTile` |
| Login details | `TitleField`, `UserNameField`, `WebsiteField`, `VerificationCodeField` |
| New Password form | `TitleField`, `UserNameTextField`, `PasswordTextField`, `WebsiteTextField`, `SaveButton`, `CancelButton` |
| Delete prompt | `ConfirmationDialogDeleteButton` |

Menu commands are matched by shortcut: the Copy commands in the Edit menu (⇧⌘C, ⌥⌘C, ⌃⌘C, ⇧⌥⌘C), Select All (⌘A) and Paste (⌘V) for the password field, New Password (⌘N) and New Window (⇧⌘N). Edit › Delete has no shortcut, so it is matched by its `delete:` identifier. If Apple renames an identifier or changes a shortcut, updating it is usually the whole fix.

## Pull requests

Match the style of the surrounding code, and keep comments to explaining why rather than what. Small, focused pull requests are easier to review.
