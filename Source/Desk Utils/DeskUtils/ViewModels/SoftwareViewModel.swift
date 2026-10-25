import Foundation
import Combine

@MainActor
class SoftwareViewModel: ObservableObject {
    @Published var items: [SoftwareItem] = []
    @Published var isScanning: Bool = false
    @Published var scanErrors: [String] = []
    @Published var searchText = ""
    @Published var selectedCategory: SoftwareSource? = .userApp
    @Published var selectedItem: SoftwareItem?

    private var cancellables = Set<AnyCancellable>()
    private let appManager = AppManager()
    private let packageManager = PackageManager()

    init() {
        $selectedCategory
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.selectedItem = self.filteredItems.first
                }
            }
            .store(in: &cancellables)
    }

    var filteredItems: [SoftwareItem] {
        let base = selectedCategory.map { cat in items.filter { $0.source == cat } } ?? items
        guard !searchText.isEmpty else { return base }
        let query = searchText
        return base.filter { item in
            item.name.localizedCaseInsensitiveContains(query) ||
            (item.version?.localizedCaseInsensitiveContains(query) ?? false) ||
            (item.description?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func itemCount(for source: SoftwareSource) -> Int {
        items.filter { $0.source == source }.count
    }

    func startScan() {
        Task {
            await scan()
        }
    }

    func resolveInstallPath(for item: SoftwareItem) async -> String? {
        switch item.source {
        case .userApp:
            return await appManager.resolveInstallPath(for: item)
        case .homebrew, .npm, .pip:
            return await packageManager.resolveInstallPath(for: item)
        }
    }

    func scan() async {
        isScanning = true
        items = []
        scanErrors = []

        async let appsResult = appManager.loadApps()
        async let packagesResult = packageManager.loadPackages()

        let (apps, packages) = await (appsResult, packagesResult)

        items = (apps.items + packages.items)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        scanErrors = apps.errors + packages.errors
        isScanning = false
        if selectedItem == nil {
            selectedItem = filteredItems.first
        }
    }
}
