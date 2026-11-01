import Foundation
import Darwin

struct FolderSyncTracker {
    private static let defaultIgnoredNames: Set<String> = [
        ".DS_Store", ".git", ".gitignore", "node-modules", ".swift-module-cache", ".build",
        "xcshareddata", "xcuserdata"
    ]

    private let fileManager = FileManager()

    func compare(roots: FolderSyncRoots) -> FolderSyncComparison {
        var result = FolderSyncComparison()
        do {
            for root in [roots.left, roots.right] {
                guard try entry(at: root).kind == .folder else {
                    throw failure("Choose a folder: \(root.path)")
                }
            }
            result.items = try compareChildren(
                left: roots.left, right: roots.right,
                relativePath: "", errors: &result.errors
            )
        } catch {
            result.errors.append(error.localizedDescription)
        }
        return result
    }

    private func entry(at url: URL) throws -> FolderSyncEntry {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let kind: FolderSyncEntry.Kind
        switch attributes[.type] as? FileAttributeType {
        case .typeDirectory: kind = .folder
        case .typeRegular: kind = .file
        case .typeSymbolicLink: kind = .symbolicLink
        default: throw failure("Unsupported entry: \(url.path)")
        }
        return FolderSyncEntry(
            kind: kind,
            size: (attributes[.size] as? NSNumber)?.uint64Value ?? 0,
            modificationDate: attributes[.modificationDate] as? Date
        )
    }

    private func compareChildren(
        left: URL?, right: URL?, relativePath: String, errors: inout [String]
    ) throws -> [FolderSyncItem] {
        // Include hidden files and package contents; filter explicit ignores below.
        let leftNames = try left.map { try fileManager.contentsOfDirectory(atPath: $0.path) } ?? []
        let rightNames = try right.map { try fileManager.contentsOfDirectory(atPath: $0.path) } ?? []
        // Swift String equality normalizes Unicode. Match filename bytes instead.
        let leftByName = Dictionary(uniqueKeysWithValues: leftNames.map { (Data($0.utf8), $0) })
        let rightByName = Dictionary(uniqueKeysWithValues: rightNames.map { (Data($0.utf8), $0) })
        let names = Set(leftByName.keys).union(rightByName.keys).sorted { $0.lexicographicallyPrecedes($1) }
        var items: [FolderSyncItem] = []
        for key in names {
            guard let name = leftByName[key] ?? rightByName[key] else { continue }
            // Filter before reading attributes or descending into either side.
            guard !Self.defaultIgnoredNames.contains(name) else { continue }
            let path = relativePath.isEmpty ? name : "\(relativePath)/\(name)"
            do {
                let leftURL = leftByName[key].flatMap { left?.appendingPathComponent($0) }
                let rightURL = rightByName[key].flatMap { right?.appendingPathComponent($0) }
                if let item = try compareItem(left: leftURL, right: rightURL, relativePath: path, name: name, errors: &errors) {
                    items.append(item)
                }
            } catch {
                errors.append("\(path): \(error.localizedDescription)")
            }
        }
        return items
    }

    private func compareItem(
        left: URL?, right: URL?, relativePath: String, name: String,
        errors: inout [String]
    ) throws -> FolderSyncItem? {
        let leftEntry = try left.map { try entry(at: $0) }
        let rightEntry = try right.map { try entry(at: $0) }
        var children: [FolderSyncItem] = []
        if leftEntry?.kind == .folder || rightEntry?.kind == .folder {
            children = try compareChildren(
                left: leftEntry?.kind == .folder ? left : nil,
                right: rightEntry?.kind == .folder ? right : nil,
                relativePath: relativePath, errors: &errors
            )
        }
        if let left, let right, let leftEntry, let rightEntry,
           leftEntry.kind == rightEntry.kind {
            switch leftEntry.kind {
            case .folder:
                if children.isEmpty { return nil }
            case .file:
                if leftEntry.size == rightEntry.size,
                   leftEntry.modificationDate == rightEntry.modificationDate,
                   try contentsEqual(left, right) { return nil }
            case .symbolicLink:
                // Compare the links themselves; never traverse their targets.
                if leftEntry.size == rightEntry.size,
                   leftEntry.modificationDate == rightEntry.modificationDate,
                   try fileManager.destinationOfSymbolicLink(atPath: left.path)
                    == fileManager.destinationOfSymbolicLink(atPath: right.path) { return nil }
            }
        }
        return FolderSyncItem(relativePath: relativePath, name: name, left: leftEntry, right: rightEntry, children: children)
    }

    private func contentsEqual(_ left: URL, _ right: URL) throws -> Bool {
        let leftHandle = try FileHandle(forReadingFrom: left)
        defer { try? leftHandle.close() }
        let rightHandle = try FileHandle(forReadingFrom: right)
        defer { try? rightHandle.close() }
        while true {
            let leftData = try leftHandle.read(upToCount: 1024 * 1024) ?? Data()
            let rightData = try rightHandle.read(upToCount: 1024 * 1024) ?? Data()
            if leftData != rightData { return false }
            if leftData.isEmpty { return true }
        }
    }

    func synchronize(item: FolderSyncItem, source: FolderSyncSide, roots: FolderSyncRoots) throws {
        let destination = roots.root(on: source.opposite).appendingPathComponent(item.relativePath)
        guard item.entry(on: source) != nil else {
            try fileManager.removeItem(at: destination)
            return
        }

        let sourceURL = roots.root(on: source).appendingPathComponent(item.relativePath)
        let parent = destination.deletingLastPathComponent()
        try ensureDirectory(parent, within: roots.root(on: source.opposite))
        let staging = parent.appendingPathComponent(".DeskUtils-sync-\(UUID().uuidString)")
        defer { try? fileManager.removeItem(at: staging) }

        // Stage the full source before removing the destination. copyfile preserves
        // timestamps, permissions, ACLs and extended attributes, including recursively.
        let flags = copyfile_flags_t(COPYFILE_ALL | COPYFILE_RECURSIVE | COPYFILE_NOFOLLOW)
        let status = sourceURL.path.withCString { sourcePath in
            staging.path.withCString { stagingPath in
                copyfile(sourcePath, stagingPath, nil, flags)
            }
        }
        guard status == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSFilePathErrorKey: sourceURL.path])
        }
        if item.entry(on: source.opposite) != nil {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: staging, to: destination)
    }

    private func ensureDirectory(_ directory: URL, within root: URL) throws {
        if directory.path == root.path { return }
        try ensureDirectory(directory.deletingLastPathComponent(), within: root)
        do {
            guard try entry(at: directory).kind == .folder else {
                throw failure("Destination parent is not a folder: \(directory.path)")
            }
        } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
            (error.code == NSFileReadNoSuchFileError || error.code == NSFileNoSuchFileError) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)
        }
    }

    private func failure(_ message: String) -> NSError {
        NSError(domain: "DeskUtils.FolderSync", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
