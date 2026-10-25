import Foundation

class PipPackageTracker: PackageTrackerProtocol, @unchecked Sendable {

    let source: SoftwareSource = .pip

    private let shellHelper = ShellHelper()

    private struct PipInvocation {
        let command: String
        let prefixArgs: [String]
    }

    func isAvailable() -> Bool {
        findPipExecutable() != nil
    }

    func scan() -> ScanResult {
        var result = ScanResult()
        guard let pip = findPipExecutable() else { return result }

        let listArgsList: [[String]] = [
            pip.prefixArgs + ["list", "-v", "--format=json"],
            pip.prefixArgs + ["list", "--format=json"],
            pip.prefixArgs + ["list", "--user", "-v", "--format=json"],
            pip.prefixArgs + ["list", "--user", "--format=json"],
        ]

        var packages: [SoftwareItem] = []
        for args in listArgsList {
            do {
                let output = try shellHelper.run(command: pip.command, arguments: args)
                packages = parsePipJSON(output)
                break
            } catch {
                // try next arg variant
            }
        }

        result.items = packages
        return result
    }

    func resolveInstallPath(for item: SoftwareItem) -> String? {
        resolvePipPath(for: item)
    }

    private func resolvePipPath(for item: SoftwareItem) -> String? {
        let strategies: [(String, [String])] = [
            ("pip3", []),
            ("pip", []),
            ("python3", ["-m", "pip"]),
        ]
        for (tool, prefixArgs) in strategies {
            guard let toolPath = shellHelper.which(tool) else { continue }
            let args = prefixArgs + ["show", item.name]
            let out = shellHelper.capture(
                executableURL: URL(fileURLWithPath: toolPath),
                arguments: args
            )
            guard out.succeeded else { continue }
            for line in out.stdout.components(separatedBy: .newlines) {
                if line.hasPrefix("Location:") {
                    let location = line
                        .replacingOccurrences(of: "Location:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    let pkgDir = "\(location)/\(item.name)"
                    if FileManager.default.fileExists(atPath: pkgDir) { return pkgDir }
                    if let distInfo = findDistInfo(in: location, packageName: item.name) { return distInfo }
                    if FileManager.default.fileExists(atPath: location) { return location }
                }
            }
        }
        return item.installPath
    }

    /// Resolves a usable pip invocation, preferring a direct pip3/pip binary and
    /// falling back to `python3 -m pip` / `python -m pip` when the standalone binary
    /// is not on PATH (common with Xcode CLT, pyenv, asdf, and conda installations).
    private func findPipExecutable() -> PipInvocation? {
        if let pip3 = shellHelper.which("pip3") {
            return PipInvocation(command: pip3, prefixArgs: [])
        }
        if let pip = shellHelper.which("pip") {
            return PipInvocation(command: pip, prefixArgs: [])
        }

        if let python3 = shellHelper.which("python3") {
            let check = shellHelper.capture(
                executableURL: URL(fileURLWithPath: python3),
                arguments: ["-m", "pip", "--version"]
            )
            if check.succeeded {
                return PipInvocation(command: python3, prefixArgs: ["-m", "pip"])
            }
        }

        if let python = shellHelper.which("python") {
            let check = shellHelper.capture(
                executableURL: URL(fileURLWithPath: python),
                arguments: ["-m", "pip", "--version"]
            )
            if check.succeeded {
                return PipInvocation(command: python, prefixArgs: ["-m", "pip"])
            }
        }

        return nil
    }

    private func parsePipJSON(_ json: String) -> [SoftwareItem] {
        guard let data = json.data(using: .utf8),
              let packages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }

        return packages.compactMap { pkg in
            guard let name = pkg["name"] as? String else { return nil }
            let version = pkg["version"] as? String
            let location = pkg["location"] as? String
            let resolvedPath = resolvePackagePath(in: location, name: name)
            return SoftwareItem(
                name: name,
                version: version,
                source: .pip,
                installPath: resolvedPath
            )
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func findDistInfo(in location: String, packageName: String) -> String? {
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: location) else { return nil }
        let normalizedTarget = packageName.lowercased().replacingOccurrences(of: "-", with: "_")
        for entry in entries where entry.lowercased().hasSuffix(".dist-info") {
            let base = entry.lowercased().replacingOccurrences(of: ".dist-info", with: "")
            let entryPkg = (base.components(separatedBy: "-").first ?? base)
                .replacingOccurrences(of: "-", with: "_")
            if entryPkg == normalizedTarget {
                return "\(location)/\(entry)"
            }
        }
        return nil
    }

    private func resolvePackagePath(in location: String?, name: String) -> String? {
        guard let location else { return nil }
        let pkgDir = "\(location)/\(name)"
        if FileManager.default.fileExists(atPath: pkgDir) { return pkgDir }
        if let distInfo = findDistInfo(in: location, packageName: name) { return distInfo }
        return location
    }
}
