import Foundation

class AppTracker {

    func scan() -> ScanResult {

        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let searchDirs = ["/Applications", "\(home)/Applications"]

        var items: [SoftwareItem] = []
        let errors: [String] = []

        for dir in searchDirs {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries {
                let fullPath = (dir as NSString).appendingPathComponent(entry)
                guard (fullPath as NSString).pathExtension == "app" else { continue }
                guard !fullPath.hasPrefix("/System/") else { continue }

                let name = (entry as NSString).deletingPathExtension
                let version = readVersion(at: fullPath)
                items.append(SoftwareItem(
                    name: name,
                    version: version,
                    source: .userApp,
                    installPath: fullPath
                ))
            }
        }

        items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return ScanResult(items: items, errors: errors)

    }

    // MARK: - Private
    private func readVersion(at appPath: String) -> String? {
        let plistPath = (appPath as NSString).appendingPathComponent("Contents/Info.plist")
        guard let dict = NSDictionary(contentsOfFile: plistPath) else { return nil }
        if let v = dict["CFBundleShortVersionString"] as? String, !v.isEmpty { return v }
        return dict["CFBundleVersion"] as? String
    }
}
