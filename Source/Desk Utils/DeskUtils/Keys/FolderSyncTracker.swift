import Foundation
import Darwin

struct FolderSyncProfileTracker {
    private let fileManager = FileManager()

    private func directory() throws -> URL {
        let support = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                         appropriateFor: nil, create: false)
        let destination = support.appendingPathComponent("DeskUtils", isDirectory: true)
            .appendingPathComponent("Sync Profiles", isDirectory: true)
        let previous = support.appendingPathComponent("Desk Utils", isDirectory: true)
            .appendingPathComponent("Sync Profiles", isDirectory: true)
        if fileManager.fileExists(atPath: previous.path) {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
            let entries = try fileManager.contentsOfDirectory(at: previous,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            for entry in entries where entry.pathExtension == "txt" {
                let values = try entry.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                guard values.isRegularFile == true, values.isSymbolicLink != true else { continue }
                let target = destination.appendingPathComponent(entry.lastPathComponent)
                guard !fileManager.fileExists(atPath: target.path) else { continue }
                try fileManager.moveItem(at: entry, to: target)
            }
        }
        return destination
    }

    private func file(named name: String) throws -> URL {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name != ".", name != "..",
              name.rangeOfCharacter(from: .controlCharacters) == nil,
              !name.contains("/"), !name.contains(":") else {
            throw failure("Enter a profile name without slashes, colons, or control characters.")
        }
        return try directory().appendingPathComponent(name + ".txt", isDirectory: false)
    }

    func names() throws -> [String] {
        let directory = try directory()
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        return try fileManager.contentsOfDirectory(at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            .filter {
                let values = try $0.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                return $0.pathExtension == "txt" && values.isRegularFile == true
                    && values.isSymbolicLink != true
            }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func load(named name: String) throws -> FolderSyncProfile {
        let url = try file(named: name)
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true else {
            throw failure("The profile must be a regular text file.")
        }
        let text = try String(contentsOf: url, encoding: .utf8)
        var fields: [String: String] = [:]
        let keys: Set<String> = ["LeftFolder", "Right Folder", "Ignores"]
        for line in text.components(separatedBy: .newlines) where !line.isEmpty {
            guard let separator = line.firstIndex(of: "=") else {
                throw failure("Invalid profile format: expected key=value.")
            }
            let key = String(line[..<separator])
            guard keys.contains(key), fields[key] == nil else {
                throw failure("Invalid or duplicate profile field: \(key).")
            }
            fields[key] = String(line[line.index(after: separator)...])
        }
        guard let left = fields["LeftFolder"], let right = fields["Right Folder"],
              let ignores = fields["Ignores"] else {
            throw failure("The profile must contain LeftFolder, Right Folder, and Ignores.")
        }
        return FolderSyncProfile(leftPath: left, rightPath: right, ignorePatterns: ignores)
    }

    func create(named name: String, profile: FolderSyncProfile) throws {
        let url = try file(named: name)
        guard [profile.leftPath, profile.rightPath, profile.ignorePatterns].allSatisfy({
            $0.rangeOfCharacter(from: .newlines) == nil
        }) else {
            throw failure("Profile fields cannot contain line breaks.")
        }
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let text = "LeftFolder=\(profile.leftPath)\nRight Folder=\(profile.rightPath)\nIgnores=\(profile.ignorePatterns)\n"
        try Data(text.utf8).write(to: url, options: [.withoutOverwriting])
    }

    private func failure(_ message: String) -> NSError {
        NSError(domain: "FolderSyncProfile", code: 1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
}

struct FolderSyncTracker {
    private static let defaultIgnoredNames: Set<String> = [
        ".DS_Store", ".git", ".gitignore", "node-modules", ".swift-module-cache", ".build",
        "xcshareddata", "xcuserdata"
    ]

    private let fileManager = FileManager()
    private let ignoredPathExpressions: [NSRegularExpression]

    init(ignoredPathPatterns: [String] = []) {
        ignoredPathExpressions = ignoredPathPatterns.compactMap { pattern in
            // Escape all syntax except our single supported wildcard. A wildcard
            // stays within one component; matching is anchored to the root.
            let expression = pattern.components(separatedBy: "*")
                .map { NSRegularExpression.escapedPattern(for: $0) }
                .joined(separator: "[^/]*")
            return try? NSRegularExpression(pattern: "\\A" + expression + "\\z")
        }
    }

    private func isIgnored(relativePath: String) -> Bool {
        let range = NSRange(relativePath.startIndex..., in: relativePath)
        return ignoredPathExpressions.contains { regex in
            regex.firstMatch(in: relativePath, range: range) != nil
        }
    }

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
            guard !isIgnored(relativePath: path) else { continue }
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
