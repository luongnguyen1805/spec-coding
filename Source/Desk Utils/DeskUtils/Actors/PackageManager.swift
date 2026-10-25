import Foundation

actor PackageManager {

    private let packageTracker = PackageTracker()

    func loadPackages() async -> ScanResult {

        async let brew = packageTracker.scanHomeBrew()
        async let npm = packageTracker.scanNPM()
        async let pip = packageTracker.scanPIP()

        let (brewResult, npmResult, pipResult) = await (brew, npm, pip)

        let allItems = (brewResult.items + npmResult.items + pipResult.items)
            .sorted { lhs, rhs in
                let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
                return lhs.source.rawValue < rhs.source.rawValue
            }
        let allErrors = brewResult.errors + npmResult.errors + pipResult.errors
        return ScanResult(items: allItems, errors: allErrors)
    }

    func resolveInstallPath(for item: SoftwareItem) -> String? {
        packageTracker.resolveInstallPath(for: item)
    }
}
