import Foundation

struct FolderSyncProfile: Sendable {
    let leftPath: String
    let rightPath: String
    let ignorePatterns: String
}

enum FolderSyncSide: Equatable, Sendable {
    case left, right

    var opposite: FolderSyncSide { self == .left ? .right : .left }
}

struct FolderSyncEntry: Sendable {
    enum Kind: Equatable, Sendable {
        case file, folder, symbolicLink
    }

    let kind: Kind
    let size: UInt64
    let modificationDate: Date?
}

struct FolderSyncItem: Identifiable, Sendable {
    // Root-relative paths remain stable across comparisons.
    let relativePath: String
    let name: String
    let left: FolderSyncEntry?
    let right: FolderSyncEntry?
    let children: [FolderSyncItem]

    // Byte identity also distinguishes canonically equivalent filenames on
    // filesystems that permit both Unicode spellings.
    var id: String { Data(relativePath.utf8).base64EncodedString() }

    func entry(on side: FolderSyncSide) -> FolderSyncEntry? {
        side == .left ? left : right
    }
}

struct FolderSyncComparison: Sendable {
    var items: [FolderSyncItem] = []
    var errors: [String] = []
}

struct FolderSyncRoots: Equatable, Sendable {
    let left: URL
    let right: URL

    func root(on side: FolderSyncSide) -> URL {
        side == .left ? left : right
    }
}

struct FolderSyncRow: Identifiable {
    let item: FolderSyncItem
    let depth: Int

    var id: String { item.id }
}
