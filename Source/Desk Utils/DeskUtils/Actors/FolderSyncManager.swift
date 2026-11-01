import Foundation

actor FolderSyncManager {
    private let tracker = FolderSyncTracker()

    // Synchronous actor methods serialize blocking work away from the main actor.
    func compare(roots: FolderSyncRoots) -> FolderSyncComparison {
        tracker.compare(roots: roots)
    }

    func synchronize(item: FolderSyncItem, source: FolderSyncSide, roots: FolderSyncRoots) -> FolderSyncComparison {
        var operationError: String?
        do {
            try tracker.synchronize(item: item, source: source, roots: roots)
        } catch {
            operationError = "\(item.relativePath): \(error.localizedDescription)"
        }
        // Also refresh after a failure, since the filesystem may have partially changed.
        var result = tracker.compare(roots: roots)
        if let operationError { result.errors.insert(operationError, at: 0) }
        return result
    }
}
