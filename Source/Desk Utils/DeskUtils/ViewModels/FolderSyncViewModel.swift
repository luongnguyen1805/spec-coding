import Foundation
import Combine

@MainActor
final class FolderSyncViewModel: ObservableObject {
    @Published var leftPath: String {
        didSet { preferences.set(leftPath, forKey: PreferenceKey.leftPath) }
    }
    @Published var rightPath: String {
        didSet { preferences.set(rightPath, forKey: PreferenceKey.rightPath) }
    }
    @Published var expandedPaths: Set<String> = []
    @Published var ignorePatterns: String {
        didSet { preferences.set(ignorePatterns, forKey: PreferenceKey.ignorePatterns) }
    }
    @Published var selectedPath: String?
    @Published private(set) var items: [FolderSyncItem] = []
    @Published private(set) var errors: [String] = []
    @Published private(set) var isBusy = false
    @Published private(set) var hasCompared = false

    private let manager = FolderSyncManager()
    private let preferences: UserDefaults
    private var comparedRoots: FolderSyncRoots?
    private var comparedPatterns: [String]?

    private var inputPatterns: [String] {
        ignorePatterns.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private enum PreferenceKey {
        static let leftPath = "folderSync.leftPath"
        static let rightPath = "folderSync.rightPath"
        static let ignorePatterns = "folderSync.ignorePatterns"
    }

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        leftPath = preferences.string(forKey: PreferenceKey.leftPath) ?? ""
        rightPath = preferences.string(forKey: PreferenceKey.rightPath) ?? ""
        ignorePatterns = preferences.string(forKey: PreferenceKey.ignorePatterns) ?? ""
    }

    var canSynchronize: Bool {
        !isBusy && errors.isEmpty && comparedRoots != nil && comparedRoots == inputRoots
            && comparedPatterns == inputPatterns
    }

    var isSynchronized: Bool {
        hasCompared && !isBusy && errors.isEmpty && items.isEmpty
    }

    var visibleRows: [FolderSyncRow] {
        func flatten(_ items: [FolderSyncItem], depth: Int) -> [FolderSyncRow] {
            items.flatMap { item in
                let row = FolderSyncRow(item: item, depth: depth)
                return [row] + (expandedPaths.contains(item.id) ? flatten(item.children, depth: depth + 1) : [])
            }
        }
        return flatten(items, depth: 0)
    }

    private var inputRoots: FolderSyncRoots? {
        func root(_ path: String) -> URL? {
            let expanded = (path as NSString).expandingTildeInPath
            guard expanded.hasPrefix("/") else { return nil }
            return URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL
        }
        guard let left = root(leftPath), let right = root(rightPath) else { return nil }
        return FolderSyncRoots(left: left, right: right)
    }

    func refresh() {
        guard !isBusy else { return }
        guard let roots = inputRoots else {
            errors = ["Enter an absolute folder path on each side."]
            hasCompared = false
            items = []
            comparedRoots = nil
            return
        }
        isBusy = true
        errors = []
        let patterns = inputPatterns
        if comparedRoots != roots {
            expandedPaths = []
            selectedPath = nil
        }
        Task {
            let result = await manager.compare(roots: roots, ignoredPathPatterns: patterns)
            accept(result, roots: roots, patterns: patterns)
        }
    }

    func synchronize(_ item: FolderSyncItem, from side: FolderSyncSide) {
        guard canSynchronize, let roots = comparedRoots else { return }
        isBusy = true
        let patterns = inputPatterns
        Task {
            let result = await manager.synchronize(item: item, source: side, roots: roots, ignoredPathPatterns: patterns)
            accept(result, roots: roots, patterns: patterns)
        }
    }

    func toggleExpansion(_ item: FolderSyncItem) {
        selectedPath = item.id
        guard !item.children.isEmpty else { return }
        if !expandedPaths.insert(item.id).inserted { expandedPaths.remove(item.id) }
    }

    func moveSelection(by offset: Int) {
        let rows = visibleRows
        guard !rows.isEmpty else {
            selectedPath = nil
            return
        }
        guard let index = rows.firstIndex(where: { $0.id == selectedPath }) else {
            selectedPath = offset < 0 ? rows.last?.id : rows.first?.id
            return
        }
        selectedPath = rows[min(max(index + offset, 0), rows.count - 1)].id
    }

    func setSelectedFolderExpanded(_ expanded: Bool) {
        guard let row = visibleRows.first(where: { $0.id == selectedPath }),
              !row.item.children.isEmpty else { return }
        if expanded {
            expandedPaths.insert(row.id)
        } else {
            expandedPaths.remove(row.id)
        }
    }

    private func accept(_ result: FolderSyncComparison, roots: FolderSyncRoots, patterns: [String]) {
        let previousIndex = visibleRows.firstIndex(where: { $0.id == selectedPath })
        items = result.items
        let rows = visibleRows
        if let previousIndex, !rows.contains(where: { $0.id == selectedPath }) {
            selectedPath = rows.isEmpty ? nil : rows[min(previousIndex, rows.count - 1)].id
        }
        errors = result.errors
        comparedRoots = roots
        comparedPatterns = patterns
        hasCompared = true
        isBusy = false
    }
}
