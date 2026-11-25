import SwiftUI

/// A small capsule showing a shortcut. Turns into a green checkmark once that field is copied.
struct Chip: View {
    let icon: String
    let label: String
    var done = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: done ? "checkmark" : icon)
            Text(label)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(done ? Color.green : Color.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(.quaternary))
    }
}

/// The first letter of a login's title on a colored circle.
struct Monogram: View {
    let title: String
    let size: CGFloat

    var body: some View {
        Text(String(title.prefix(1)).uppercased())
            .font(.system(size: size * 0.47, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(color))
    }

    /// Derived from the title so the same site always gets the same color.
    private var color: Color {
        let n = title.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return Color(hue: Double(n % 12) / 12, saturation: 0.45, brightness: 0.72)
    }
}

extension Field {
    var label: String {
        switch self {
        case .username: "Gebruikersnaam"
        case .password: "Wachtwoord"
        case .code: "Verificatiecode"
        case .website: "Website"
        }
    }

    var icon: String {
        switch self {
        case .username: "person.fill"
        case .password: "key.fill"
        case .code: "clock.fill"
        case .website: "globe"
        }
    }
}
