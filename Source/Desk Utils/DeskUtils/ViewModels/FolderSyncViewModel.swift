import Foundation
import Combine

@MainActor
final class FolderSyncViewModel: ObservableObject {
    @Published var leftPath: String {
        didSet { saveFields() }
    }
    @Published var rightPath: String {
        didSet { saveFields() }
    }
    @Published var expandedPaths: Set<String> = []
    @Published var ignorePatterns: String {
        didSet { saveFields() }
    }
    @Published var selectedPath: String?
    @Published private(set) var items: [FolderSyncItem] = []
    @Published private(set) var errors: [String] = []
    @Published private(set) var isBusy = false
    @Published private(set) var hasCompared = false
    @Published private(set) var profileNames: [String] = []
    @Published private(set) var selectedProfile: String?
    @Published var profileError: String?

    private let manager = FolderSyncManager()
    private let preferences: UserDefaults
    private var comparedRoots: FolderSyncRoots?
    private var comparedPatterns: [String]?
    private var didLoadProfiles = false
    private var isLoadingFields = false
    private var profileSaveTask: Task<Void, Never>?

    private var inputPatterns: [String] {
        ignorePatterns.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private enum PreferenceKey {
        static let leftPath = "folderSync.leftPath"
        static let rightPath = "folderSync.rightPath"
        static let ignorePatterns = "folderSync.ignorePatterns"
        static let lastProfile = "folderSync.lastProfile"
    }

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        leftPath = preferences.string(forKey: PreferenceKey.leftPath) ?? ""
        rightPath = preferences.string(forKey: PreferenceKey.rightPath) ?? ""
        ignorePatterns = preferences.string(forKey: PreferenceKey.ignorePatterns) ?? ""
        selectedProfile = preferences.string(forKey: PreferenceKey.lastProfile)
    }

    func loadProfiles() async {
        guard !didLoadProfiles, !isBusy else { return }
        didLoadProfiles = true
        isBusy = true
        defer { isBusy = false }
        do {
            profileNames = try await manager.profileNames()
            if let selectedProfile {
                apply(try await manager.loadProfile(named: selectedProfile))
            }
        } catch {
            profileError = "Could not load sync profiles: \(error.localizedDescription)"
        }
    }

    func selectProfile(_ name: String?) async {
        guard !isBusy else { return }
        guard let name else {
            selectedProfile = nil
            preferences.removeObject(forKey: PreferenceKey.lastProfile)
            apply(FolderSyncProfile(
                leftPath: preferences.string(forKey: PreferenceKey.leftPath) ?? "",
                rightPath: preferences.string(forKey: PreferenceKey.rightPath) ?? "",
                ignorePatterns: preferences.string(forKey: PreferenceKey.ignorePatterns) ?? ""
            ))
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let profile = try await manager.loadProfile(named: name)
            apply(profile)
            selectedProfile = name
            preferences.set(name, forKey: PreferenceKey.lastProfile)
        } catch {
            profileError = "Could not load profile \(name): \(error.localizedDescription)"
        }
    }

    func createProfile(named name: String) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        let profile = FolderSyncProfile(leftPath: leftPath, rightPath: rightPath,
                                        ignorePatterns: ignorePatterns)
        do {
            try await manager.createProfile(named: name, profile: profile)
        } catch {
            profileError = "Could not create profile: \(error.localizedDescription)"
            return
        }
        if !profileNames.contains(name) { profileNames.append(name) }
        profileNames.sort { $0.localizedStandardCompare($1) == .orderedAscending }
        selectedProfile = name
        preferences.set(name, forKey: PreferenceKey.lastProfile)
    }

    func renameSelectedProfile(to newName: String) async {
        guard !isBusy, let name = selectedProfile, newName != name else { return }
        isBusy = true
        defer { isBusy = false }
        // Pending field saves target the old file name; let them land first.
        await profileSaveTask?.value
        do {
            try await manager.renameProfile(named: name, to: newName)
        } catch {
            profileError = "Could not rename profile \(name): \(error.localizedDescription)"
            return
        }
        profileNames.removeAll { $0 == name }
        if !profileNames.contains(newName) { profileNames.append(newName) }
        profileNames.sort { $0.localizedStandardCompare($1) == .orderedAscending }
        selectedProfile = newName
        preferences.set(newName, forKey: PreferenceKey.lastProfile)
    }

    private func apply(_ profile: FolderSyncProfile) {
        // Loading fields is not an edit; never write them back.
        isLoadingFields = true
        defer { isLoadingFields = false }
        leftPath = profile.leftPath
        rightPath = profile.rightPath
        ignorePatterns = profile.ignorePatterns
    }

    private func saveFields() {
        guard !isLoadingFields else { return }
        guard let name = selectedProfile else {
            preferences.set(leftPath, forKey: PreferenceKey.leftPath)
            preferences.set(rightPath, forKey: PreferenceKey.rightPath)
            preferences.set(ignorePatterns, forKey: PreferenceKey.ignorePatterns)
            return
        }
        let profile = FolderSyncProfile(leftPath: leftPath, rightPath: rightPath,
                                        ignorePatterns: ignorePatterns)
        // Chain saves so per-keystroke writes land in edit order.
        let previous = profileSaveTask
        profileSaveTask = Task { [manager] in
            await previous?.value
            do {
                try await manager.saveProfile(named: name, profile: profile)
            } catch {
                profileError = "Could not save profile \(name): \(error.localizedDescription)"
            }
        }
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
        let previousItems = items
        Task {
            let result = await manager.synchronize(item: item, source: side, roots: roots,
                                                   ignoredPathPatterns: patterns, previousItems: previousItems)
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
