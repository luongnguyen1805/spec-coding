import SwiftUI

extension SoftwareSource {
    var iconName: String {
        switch self {
        case .userApp: return "app.fill"
        case .homebrew: return "cup.and.saucer.fill"
        case .npm: return "shippingbox.fill"
        case .pip: return "puzzlepiece.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .userApp: return .blue
        case .homebrew: return .orange
        case .npm: return .red
        case .pip: return .green
        }
    }

    /// Returns the user-facing noun for this source type.
    /// "App" for user applications, "Package" for Homebrew / NPM / Pip.
    var localizedItemNoun: String {
        switch self {
        case .userApp: return "App"
        case .homebrew, .npm, .pip: return "Package"
        }
    }

    var gradient: LinearGradient {
        let colors: [Color]
        switch self {
        case .userApp: colors = [.blue, .indigo]
        case .homebrew: colors = [.orange, .brown]
        case .npm: colors = [.red, .pink]
        case .pip: colors = [.green, .teal]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
