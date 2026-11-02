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

    func saveProfile(named name: String, profile: FolderSyncProfile) throws {
        try FolderSyncProfileTracker().save(named: name, profile: profile)
    }

    func renameProfile(named name: String, to newName: String) throws {
        try FolderSyncProfileTracker().rename(named: name, to: newName)
    }

    // Synchronous actor methods serialize blocking work away from the main actor.
    func compare(roots: FolderSyncRoots, ignoredPathPatterns: [String]) -> FolderSyncComparison {
        FolderSyncTracker(ignoredPathPatterns: ignoredPathPatterns).compare(roots: roots)
    }

    func synchronize(item: FolderSyncItem, source: FolderSyncSide, roots: FolderSyncRoots,
                     ignoredPathPatterns: [String], previousItems: [FolderSyncItem]) -> FolderSyncComparison {
        let tracker = FolderSyncTracker(ignoredPathPatterns: ignoredPathPatterns)
        do {
            try tracker.synchronize(item: item, source: source, roots: roots)
        } catch {
            // A failed operation may have partially changed the filesystem.
            // Retain a full recovery comparison for this exceptional case.
            var result = tracker.compare(roots: roots)
            result.errors.insert("\(item.relativePath): \(error.localizedDescription)", at: 0)
            return result
        }
        return tracker.refresh(item: item, roots: roots, previousItems: previousItems)
    }
}
