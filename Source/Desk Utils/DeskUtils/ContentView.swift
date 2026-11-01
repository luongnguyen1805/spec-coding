import SwiftUI

struct ContentView: View {
    @State private var showSoftwareManager = false
    @State private var showFolderManager = false
    @State private var showFolderSync = false
    @StateObject private var softwareViewModel = SoftwareViewModel()
    @StateObject private var foldersViewModel = ManageFoldersViewModel()
    @StateObject private var folderSyncViewModel = FolderSyncViewModel()

    var body: some View {
        if showSoftwareManager {
            SoftwareManagerView(viewModel: softwareViewModel) {
                showSoftwareManager = false
            }
        } else if showFolderManager {
            FolderManagerView(viewModel: foldersViewModel) {
                showFolderManager = false
            }
        } else if showFolderSync {
            FolderSyncView(viewModel: folderSyncViewModel) {
                showFolderSync = false
            }
        } else {
            DashboardView(
                showSoftwareManager: $showSoftwareManager,
                showFolderManager: $showFolderManager,
                showFolderSync: $showFolderSync
            )
        }
    }
}
