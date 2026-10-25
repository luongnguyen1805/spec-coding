import Foundation

struct ScanResult {
    var items: [SoftwareItem]
    var errors: [String]

    init(items: [SoftwareItem] = [], errors: [String] = []) {
        self.items = items
        self.errors = errors
    }
}
