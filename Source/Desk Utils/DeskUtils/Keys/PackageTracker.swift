import Foundation

/// Thin coordinator that owns the per-ecosystem trackers and exposes the scanning
/// API relied upon by `PackageManager`. See `.knowledge/PackageTrackers.md` for why
/// the ecosystem-specific logic lives in the individual trackers instead of here.
class PackageTracker: @unchecked Sendable {

    private let homebrewTracker: PackageTrackerProtocol = HomebrewPackageTracker()
    private let npmTracker: PackageTrackerProtocol = NpmPackageTracker()
    private let pipTracker: PackageTrackerProtocol = PipPackageTracker()

    func resolveInstallPath(for item: SoftwareItem) -> String? {
        switch item.source {
        case .homebrew:
            return homebrewTracker.resolveInstallPath(for: item)
        case .npm:
            return npmTracker.resolveInstallPath(for: item)
        case .pip:
            return pipTracker.resolveInstallPath(for: item)
        default:
            return item.installPath
        }
    }

    func scanHomeBrew() -> ScanResult {
        guard homebrewTracker.isAvailable() else { return ScanResult() }
        return homebrewTracker.scan()
    }

    func scanNPM() -> ScanResult {
        guard npmTracker.isAvailable() else { return ScanResult() }
        return npmTracker.scan()
    }

    func scanPIP() -> ScanResult {
        guard pipTracker.isAvailable() else { return ScanResult() }
        return pipTracker.scan()
    }
}
