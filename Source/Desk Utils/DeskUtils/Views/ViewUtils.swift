import Foundation

enum ViewUtils {
    static func formattedSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        if mb >= 1 { return String(format: "%.1f MB", mb) }
        return String(format: "%.0f KB", kb)
    }

    static func formattedFolderSummary(fileCount: Int, sizeBytes: Int64) -> String {
        let filesLabel = fileCount == 1 ? "file" : "files"
        return "\(fileCount.formatted()) \(filesLabel) | \(formattedSize(sizeBytes))"
    }
}
