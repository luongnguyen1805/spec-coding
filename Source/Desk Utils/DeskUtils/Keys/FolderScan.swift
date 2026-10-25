import Foundation

final class FolderScan: Codable {

    // MARK: - Properties

    let name: String
    let path: String

    var sizeBytes: Int64 = 0
    var fileCount: Int = 0
    var childs: [String: FolderScan] = [:]

    // MARK: - Initialization

    init(name: String, path: String) {
        self.name = name
        self.path = path
    }

    // MARK: - Internal

    func toFolderItem(maxDepth: Int) -> FolderItem {
        guard maxDepth > 0 else {
            return FolderItem(name: name, path: path, sizeBytes: sizeBytes, childs: [:], fileCount: fileCount)
        }
        return FolderItem(
            name: name,
            path: path,
            sizeBytes: sizeBytes,
            childs: childs.mapValues { $0.toFolderItem(maxDepth: maxDepth - 1) },
            fileCount: fileCount
        )
    }
}
