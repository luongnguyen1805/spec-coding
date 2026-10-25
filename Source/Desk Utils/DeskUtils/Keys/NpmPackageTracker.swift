import Foundation

class NpmPackageTracker: PackageTrackerProtocol, @unchecked Sendable {

    let source: SoftwareSource = .npm

    private let shellHelper = ShellHelper()

    func isAvailable() -> Bool {
        shellHelper.which("npm") != nil
    }

    func scan() -> ScanResult {
        var result = ScanResult()
        guard let npmPath = shellHelper.which("npm") else { return result }

        let rootOut = shellHelper.capture(executableURL: URL(fileURLWithPath: npmPath), arguments: ["root", "-g"])
        let npmRoot: String? = rootOut.succeeded ? rootOut.stdout.trimmingCharacters(in: .whitespacesAndNewlines) : nil

        let out = shellHelper.capture(executableURL: URL(fileURLWithPath: npmPath), arguments: ["list", "-g", "--depth=0", "--json"])
        if out.stdout.isEmpty {
            result.errors.append("npm scan failed: \(out.stderr)")
            return result
        }
        if !out.succeeded {
            result.errors.append("npm reported warnings (exit \(out.exitCode))")
        }
        result.items = parseNPMJSON(out.stdout, npmRoot: npmRoot)
        return result
    }

    func resolveInstallPath(for item: SoftwareItem) -> String? {
        item.installPath
    }

    private func parseNPMJSON(_ json: String, npmRoot: String?) -> [SoftwareItem] {
        guard let startIndex = json.firstIndex(of: "{"),
              let data = String(json[startIndex...]).data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dependencies = root["dependencies"] as? [String: Any] else { return [] }

        var items: [SoftwareItem] = []
        for (name, info) in dependencies {
            let pkg = info as? [String: Any]
            let version = pkg?["version"] as? String
            let resolved = pkg?["resolved"] as? String
            let pkgPath = pkg?["path"] as? String
            let installPath = pkgPath ?? npmRoot.map { "\($0)/\(name)" }
            items.append(SoftwareItem(
                name: name,
                version: version,
                source: .npm,
                installPath: installPath,
                metadata: resolved.map { ["resolved": $0] }
            ))
        }

        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
