import Foundation
import Darwin

class FolderTracker: @unchecked Sendable {

    // MARK: - Types

    /// Once this many entries at the front of `scanningFolders` have been processed,
    /// they're dropped in one bulk shift instead of being kept around for the rest of the scan.
    private static let scanQueueCompactionThreshold = 1000

    /// Wall-clock cadence for persisting scan state as a crash/force-quit resume
    /// safety net, decoupled from `scanQueueCompactionThreshold`'s unrelated purpose
    /// of bounding `scanningFolders`' array memory footprint.
    private static let persistenceInterval: TimeInterval = 5.0

    /// Depth (from the "/" root) kept when converting to `FolderItem` for reporting.
    /// The UI (drive → big folder → sub folder, then 3 more nested levels) never renders
    /// past depth 6, so deeper nodes are reported with their sizeBytes but no childs —
    /// size is still correct since propagateSize already bubbled it up to every ancestor.
    private static let maxReportedDepth = 6

    private static let persistenceDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("DeskUtils/FolderTracker", isDirectory: true)
    }()
    private static let scanningFoldersURL = persistenceDirectory.appendingPathComponent("scanningFolders.json")
    private static let scannedFoldersURL = persistenceDirectory.appendingPathComponent("scannedFolders.json")

    // MARK: - Properties

    private let workerQueue = DispatchQueue(label: "FolderTracker.worker", qos: .utility)
    
    private var scannedFolders: [String: FolderScan] = [:]
    private var scanningFolders: [String] = []
    
    private var onReport: (@Sendable ([String: FolderItem]) -> Void)?
    private var onComplete: (@Sendable ([String: FolderItem]) -> Void)?
    private var isScanning = false
    private let fileManager = FileManager.default

    /// Written from any thread by `stop()` while the worker loop is running, so it is
    /// guarded by its own lock rather than by `workerQueue` (which is busy with the scan).
    private let cancelLock = NSLock()
    private var cancelRequested = false

    private var isCancelRequested: Bool {
        cancelLock.lock()
        defer { cancelLock.unlock() }
        return cancelRequested
    }
    
    private let ignoreFolderNames = [".nofollow", ".resolve", ".vol", ".Spotlight-V100", ".Trashes", ".TemporaryItems", ".fseventsd", ".DocumentRevisions-V100"]
    private let ignoreFileNames = [".DS_Store", ".VolumeIcon.icns", ".apdisk", ".localized"]

    // MARK: - Initialization

    init() {}

    // MARK: - Internal
    
    func fetchLoadedFoldersAndInProgressStatus() -> ([String: FolderItem], Bool) {
        guard let persisted = self.loadPersistedState() else {
            return ([:], false)
        }
                
        self.scannedFolders = persisted.scannedFolders
        self.scanningFolders = persisted.scanningFolders
        
        let snapshot = makeSnapshot()
        let isInProgress = self.scanningFolders.isEmpty == false
        return (snapshot, isInProgress)
    }

    func scan(
        onReport: @escaping @Sendable ([String: FolderItem]) -> Void,
        onComplete: @escaping @Sendable ([String: FolderItem]) -> Void
    ) {
        workerQueue.async {
            if self.isScanning {
                self.onReport = onReport
                self.onComplete = onComplete
                return
            }

            self.isScanning = true
            self.setCancelRequested(false)
            self.onReport = onReport
            self.onComplete = onComplete

            if let persisted = self.loadPersistedState(), !persisted.scanningFolders.isEmpty {
                self.scannedFolders = persisted.scannedFolders
                self.scanningFolders = persisted.scanningFolders
            } else {
                self.scannedFolders = ["/": FolderScan(name: self.rootVolumeDisplayName(), path: "/")]
                self.scanningFolders = ["/"]
            }

            var lastReportTime = Date()
            var lastPersistTime = Date()
            var currentIndex = 0
            var wasCancelled = false

            while currentIndex < self.scanningFolders.count {

                if self.isCancelRequested {
                    wasCancelled = true
                    break
                }

                autoreleasepool {
                    if Date().timeIntervalSince(lastReportTime) >= 1.0 {
                        self.reportSnapshot()
                        lastReportTime = Date()
                    }

                    let folderPath = self.scanningFolders[currentIndex]
                    
                    currentIndex += 1

                    let scanResult = self.scanDirectory(folderPath)
                    
                    for subfolder in scanResult.folders {
                        if subfolder.components(separatedBy: "/").count < 8 {
                            self.insertFolder(path: subfolder)
                        }
                        
                        self.scanningFolders.append(subfolder)
                    }

                    self.propagateSize(for: folderPath, size: scanResult.fileSize, fileCount: scanResult.fileCount)

                    if currentIndex >= Self.scanQueueCompactionThreshold {
                        // `removeFirst(_:)` would shift elements down but keep the buffer's
                        // already-grown capacity; rebuilding drops the old (larger) backing
                        // storage and replaces it with one sized to just what's left.
                        self.scanningFolders = Array(self.scanningFolders[currentIndex...])
                        currentIndex = 0
                        
                        if Date().timeIntervalSince(lastPersistTime) >= Self.persistenceInterval {
                            self.persistState()
                            lastPersistTime = Date()
                        }
                    }
                }

            }

            if wasCancelled {
                // Keep only the unprocessed folders so the next scan resumes from here.
                self.scanningFolders = Array(self.scanningFolders[currentIndex...])
                self.persistState()
                self.onReport = nil
                self.onComplete = nil
                self.isScanning = false
                return
            }

            let finalSnapshot = self.makeSnapshot()
            self.onReport?(finalSnapshot)
            self.onComplete?(finalSnapshot)

            self.scanningFolders = []
            self.persistState()
            self.isScanning = false
        }
    }

    /// Requests the running scan to stop before its next folder. The worker persists the
    /// remaining queue for resumption and sends no further report or completion.
    /// No-op when idle: the flag is reset when the next scan starts.
    func stop() {
        setCancelRequested(true)
    }

    // MARK: - Private

    private func setCancelRequested(_ value: Bool) {
        cancelLock.lock()
        cancelRequested = value
        cancelLock.unlock()
    }

    private func makeSnapshot() -> [String: FolderItem] {
        scannedFolders.mapValues { $0.toFolderItem(maxDepth: Self.maxReportedDepth) }
    }

    private func rootVolumeDisplayName() -> String {
        let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeLocalizedNameKey])
        return values?.volumeLocalizedName ?? "Mac"
    }

    private func persistState() {
        try? fileManager.createDirectory(at: Self.persistenceDirectory, withIntermediateDirectories: true)
        if let scannedData = try? JSONEncoder().encode(self.scannedFolders) {
            try? scannedData.write(to: Self.scannedFoldersURL)
        }
        if let scanningData = try? JSONEncoder().encode(self.scanningFolders) {
            try? scanningData.write(to: Self.scanningFoldersURL)
        }
    }

    private func loadPersistedState() -> (scannedFolders: [String: FolderScan], scanningFolders: [String])? {
        guard let scannedData = try? Data(contentsOf: Self.scannedFoldersURL),
              let scanningData = try? Data(contentsOf: Self.scanningFoldersURL),
              let scannedFolders = try? JSONDecoder().decode([String: FolderScan].self, from: scannedData),
              let scanningFolders = try? JSONDecoder().decode([String].self, from: scanningData) else {
            return nil
        }
        return (scannedFolders, scanningFolders)
    }

    private func reportSnapshot() {
        let snapshot = makeSnapshot()
        onReport?(snapshot)
    }

    private func scanDirectory(_ folder: String) -> (folders: [String], fileSize: Int64, fileCount: Int) {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: folder) else {
            return ([], 0, 0)
        }

        var folders: [String] = []
        var fileSize: Int64 = 0
        var fileCount = 0
        
        for entry in entries {
            let fullPath = (folder as NSString).appendingPathComponent(entry)
            let attrs = try? fileManager.attributesOfItem(atPath: fullPath)

            var isDir: ObjCBool = false
            fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)

            if isDir.boolValue {
                if let type = attrs?[.type] as? FileAttributeType, type != .typeDirectory {
                    continue
                }
                if fullPath == "/dev" || fullPath == "/cores" || fullPath == "/Volumes" || fullPath == "/System/Volumes" {
                    continue
                }
                if fullPath.hasPrefix("/Volumes/") || fullPath.hasPrefix("/System/Volumes/") {
                    continue
                }
                
                if ignoreFolderNames.contains(entry) {
                    continue
                }
                
                folders.append(fullPath)
            } else  {
                if let type = attrs?[.type] as? FileAttributeType, type != .typeRegular {
                    continue
                }
                if entry.hasPrefix("._") {
                    continue
                }
                if ignoreFileNames.contains(entry) {
                    continue
                }

                fileSize += (attrs?[.size] as? NSNumber)?.int64Value ?? 0
                fileCount += 1
            }
        }

        return (folders, fileSize, fileCount)
    }

    private func treeLocation(for path: String) -> (driveName: String, components: [String])? {
        let components = path.split(separator: "/").map(String.init)
        //let driveName = path.hasPrefix("/") ? "/" :
        return ("/", components)
    
    }

    private func insertFolder(path: String) {
                
        guard let (driveName, components) = treeLocation(for: path),
              let drive = scannedFolders[driveName] else {
            return
        }
        
        var currentNode: FolderScan? = drive
        var fullPath = "/"
        for component in components {
            fullPath = (fullPath as NSString).appendingPathComponent(component)

            let theNode = currentNode?.childs[component]
            if theNode == nil {
                let newFolderScan = FolderScan(name: component, path: fullPath)
                currentNode?.childs[component] = newFolderScan
                currentNode = newFolderScan
            } else {
                currentNode = theNode
            }
        }
        
    }

    private func propagateSize(for path: String, size: Int64, fileCount: Int) {
        guard size > 0 || fileCount > 0 else {
            return
        }
        guard let (driveName, components) = treeLocation(for: path),
              let drive = scannedFolders[driveName] else { return }

        var currentNode: FolderScan? = drive
        currentNode?.sizeBytes += size
        currentNode?.fileCount += fileCount

        for component in components {
            currentNode = currentNode?.childs[component]
            if currentNode == nil {
                break
            }

            currentNode?.sizeBytes += size
            currentNode?.fileCount += fileCount
        }

    }
}
