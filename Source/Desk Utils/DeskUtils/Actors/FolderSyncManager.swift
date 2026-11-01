import Foundation

actor FolderSyncManager {
    func profileNames() throws -> [String] {
        try FolderSyncProfileTracker().names()
    }

    func loadProfile(named name: String) throws -> FolderSyncProfile {
        try FolderSyncProfileTracker().load(named: name)
    }

    func createProfile(named name: String, profile: FolderSyncProfile) throws {
        try FolderSyncProfileTracker().create(named: name, profile: profile)
    }

    // Synchronous actor methods serialize blocking work away from the main actor.
    func compare(roots: FolderSyncRoots, ignoredPathPatterns: [String]) -> FolderSyncComparison {
        FolderSyncTracker(ignoredPathPatterns: ignoredPathPatterns).compare(roots: roots)
    }

    func synchronize(item: FolderSyncItem, source: FolderSyncSide, roots: FolderSyncRoots, ignoredPathPatterns: [String]) -> FolderSyncComparison {
        let tracker = FolderSyncTracker(ignoredPathPatterns: ignoredPathPatterns)
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
