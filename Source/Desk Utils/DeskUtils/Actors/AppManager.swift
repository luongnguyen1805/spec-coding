import Foundation

actor AppManager {

    private let appTracker = AppTracker()

    func loadApps() -> ScanResult {
        appTracker.scan()
    }

    func resolveInstallPath(for item: SoftwareItem) -> String? {
        item.installPath
    }
}
