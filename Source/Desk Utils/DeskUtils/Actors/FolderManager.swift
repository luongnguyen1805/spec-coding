import Foundation

actor FolderManager {
    private let tracker = FolderTracker()

    init() {}

    func startScanning(
        onReport: @escaping @Sendable ([String: FolderItem]) -> Void,
        onComplete: @escaping @Sendable ([String: FolderItem]) -> Void
    ) {
        tracker.scan(onReport: onReport, onComplete: onComplete)
    }
    
    func fetchLoadedFoldersAndInProgressStatus() -> ([String: FolderItem], Bool) {
        tracker.fetchLoadedFoldersAndInProgressStatus()
    }
}
