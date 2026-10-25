import Foundation

protocol PackageTrackerProtocol {
    var source: SoftwareSource { get }
    func isAvailable() -> Bool
    func scan() -> ScanResult
    func resolveInstallPath(for item: SoftwareItem) -> String?
}
