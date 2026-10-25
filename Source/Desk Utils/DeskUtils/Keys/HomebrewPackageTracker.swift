import Foundation

class HomebrewPackageTracker: PackageTrackerProtocol, @unchecked Sendable {

    let source: SoftwareSource = .homebrew

    private let shellHelper = ShellHelper()

    func isAvailable() -> Bool {
        shellHelper.which("brew") != nil
    }

    func scan() -> ScanResult {
        var result = ScanResult()
        guard let brewPath = shellHelper.which("brew") else { return result }

        do {
            let output = try shellHelper.run(command: brewPath, arguments: ["info", "--json=v2", "--installed"])
            result.items = parseBrewJSON(output)
        } catch {
            result.errors.append("homebrew scan failed: \(error.localizedDescription)")
        }
        return result
    }

    func resolveInstallPath(for item: SoftwareItem) -> String? {
        guard let brewPath = shellHelper.which("brew") else { return item.installPath }
        let out = shellHelper.capture(
            executableURL: URL(fileURLWithPath: brewPath),
            arguments: ["--prefix", item.name]
        )
        if out.succeeded {
            let dir = out.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if !dir.isEmpty && FileManager.default.fileExists(atPath: dir) {
                return dir
            }
        }
        return item.installPath
    }

    private func parseBrewJSON(_ json: String) -> [SoftwareItem] {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }

        var items: [SoftwareItem] = []

        let formulae = root["formulae"] as? [[String: Any]] ?? []
        for formula in formulae {
            guard let name = formula["name"] as? String else { continue }
            let installedList = formula["installed"] as? [[String: Any]] ?? []
            let version = installedList.first?["version"] as? String
            let desc = formula["desc"] as? String
            let deps = formula["dependencies"] as? [String]
            let prefix = (formula["prefix"] as? String) ?? brewCellarPath(name: name, version: version)

            items.append(SoftwareItem(
                name: name,
                version: version,
                source: .homebrew,
                installPath: prefix,
                description: desc,
                dependencies: deps?.isEmpty == false ? deps : nil
            ))
        }

        let casks = root["casks"] as? [[String: Any]] ?? []
        for cask in casks {
            guard let token = cask["token"] as? String else { continue }
            let version: String?
            if let s = cask["installed"] as? String {
                version = s
            } else if let arr = cask["installed"] as? [String] {
                version = arr.first
            } else {
                version = nil
            }
            let desc = cask["desc"] as? String
            let appdir = cask["appdir"] as? String

            items.append(SoftwareItem(
                name: token,
                version: version,
                source: .homebrew,
                installPath: appdir,
                description: desc
            ))
        }

        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func brewCellarPath(name: String, version: String?) -> String? {
        guard let version else { return nil }
        let prefix = FileManager.default.fileExists(atPath: "/opt/homebrew") ? "/opt/homebrew" : "/usr/local"
        return "\(prefix)/Cellar/\(name)/\(version)"
    }
}
