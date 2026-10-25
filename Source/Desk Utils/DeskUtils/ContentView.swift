import SwiftUI

struct ContentView: View {
    @State private var showSoftwareManager = false
    @State private var showFolderManager = false
    @StateObject private var softwareViewModel = SoftwareViewModel()
    @StateObject private var foldersViewModel = ManageFoldersViewModel()

    var body: some View {
        if showSoftwareManager {
            SoftwareManagerView(viewModel: softwareViewModel) {
                showSoftwareManager = false
            }
        } else if showFolderManager {
            FolderManagerView(viewModel: foldersViewModel) {
                showFolderManager = false
            }
        } else {
            DashboardView(
                showSoftwareManager: $showSoftwareManager,
                showFolderManager: $showFolderManager
            )
        }
    }
}
