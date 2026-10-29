import Foundation
import Combine

@MainActor
class ManageFoldersViewModel: ObservableObject {
    private static let subFoldersMaxDepth = 3

    @Published var foldersByDrive: [String: FolderItem] = [:]

    @Published var isScanning: Bool = false

    @Published var topFolders: [FolderItem] = []
    @Published var selectedTopFolder: FolderItem? {
        didSet { refreshBigFolders() }
    }

    @Published var bigFolders: [FolderItem] = []
    @Published var selectedBigFolder: FolderItem? {
        didSet { refreshSubFolders() }
    }

    @Published var subFolders: [FolderItem] = []

    private func refreshSelections() {
        topFolders = sortedShallowClones(of: foldersByDrive.values)
        selectedTopFolder = topFolders.first { $0.id == selectedTopFolder?.id }
    }

    private func refreshBigFolders() {
        guard let selectedTopFolder, let source = foldersByDrive[selectedTopFolder.path] else {
            bigFolders = []
            selectedBigFolder = nil
            return
        }

        bigFolders = sortedShallowClones(of: source.childs.values)
        selectedBigFolder = bigFolders.first { $0.id == selectedBigFolder?.id }
    }

    private func refreshSubFolders() {
        guard let selectedTopFolder,
              let selectedBigFolder,
              let topSource = foldersByDrive[selectedTopFolder.path],
              let source = topSource.childs[selectedBigFolder.name] else {
            
            DispatchQueue.main.async {
                self.subFolders = []
            }
            
            return
        }

        DispatchQueue.main.async {
            self.subFolders = source.childs.values
                .map { $0.cloned(maxDepth: Self.subFoldersMaxDepth) }
                .sorted { $0.sizeBytes > $1.sizeBytes }
        }
    }

    private func sortedShallowClones<S: Sequence>(of items: S) -> [FolderItem] where S.Element == FolderItem {
        items
            .map { $0.cloned(maxDepth: 0) }
            .sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private let folderManager = FolderManager()
    private var consumeTask: Task<Void, Never>?
    
    func handleAppear() async {
        
        let (loadedFolders,isInProgress) = await folderManager.fetchLoadedFoldersAndInProgressStatus()
        
        if loadedFolders.isEmpty || isInProgress {
            startScan()
        } else {
            self.foldersByDrive = loadedFolders
            self.refreshSelections()
        }
        
    }

    func startScan() {
        isScanning = true
        consumeTask = Task {
            await folderManager.startScanning(
                onReport: { [weak self] partial in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.foldersByDrive = partial
                        self.refreshSelections()
                    }
                },
                onComplete: { [weak self] final in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.foldersByDrive = final
                        self.refreshSelections()
                        self.isScanning = false
                        self.consumeTask = nil
                    }
                }
            )
        }
    }

    func stopScan() {
        consumeTask?.cancel()
        consumeTask = nil
        isScanning = false
        Task {
            await folderManager.stopScanning()
        }
    }
}
