import Foundation

struct FolderItem: Identifiable, Hashable, Sendable {
    struct SizeRefreshID: Hashable, Sendable {
        let folderID: String
        let sizeBytes: Int64
        let fileCount: Int
    }

    let id: String
    let name: String
    let path: String
    var sizeBytes: Int64
    var fileCount: Int
    var childs: [String: FolderItem]

    var sortedChilds: [FolderItem] {
        childs.values.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    var sizeRefreshID: SizeRefreshID {
        SizeRefreshID(folderID: id, sizeBytes: sizeBytes, fileCount: fileCount)
    }

    init(name: String, path: String, sizeBytes: Int64 = 0, childs: [String: FolderItem] = [:], fileCount: Int = 0) {
        self.id = path
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.childs = childs
        self.fileCount = fileCount
    }

    static func == (lhs: FolderItem, rhs: FolderItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func cloned(maxDepth: Int) -> FolderItem {
        guard maxDepth > 0 else {
            return FolderItem(name: name, path: path, sizeBytes: sizeBytes, childs: [:], fileCount: fileCount)
        }
        let clonedChilds = childs.mapValues { $0.cloned(maxDepth: maxDepth - 1) }
        return FolderItem(name: name, path: path, sizeBytes: sizeBytes, childs: clonedChilds, fileCount: fileCount)
    }
}
