import Foundation

enum SoftwareSource: String, CaseIterable, Hashable {
    case userApp = "Applications"
    case homebrew = "homebrew"
    case pip = "pip"
    case npm = "npm"
}

struct SoftwareItem: Identifiable, Hashable {
    let id: String
    var name: String
    var version: String?
    var source: SoftwareSource
    var installPath: String?
    var description: String?
    var dependencies: [String]?
    var metadata: [String: String]?

    init(
        name: String,
        version: String? = nil,
        source: SoftwareSource,
        installPath: String? = nil,
        description: String? = nil,
        dependencies: [String]? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = installPath ?? "\(source.rawValue):\(name)"
        self.name = name
        self.version = version
        self.source = source
        self.installPath = installPath
        self.description = description
        self.dependencies = dependencies
        self.metadata = metadata
    }

    static func == (lhs: SoftwareItem, rhs: SoftwareItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
