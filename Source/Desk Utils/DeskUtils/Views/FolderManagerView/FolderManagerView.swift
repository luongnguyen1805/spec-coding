import SwiftUI

struct FolderManagerView: View {
    @ObservedObject var viewModel: ManageFoldersViewModel
    let onBack: () -> Void

    var body: some View {
        NavigationSplitView {
            FirstPanelView(viewModel: viewModel, onBack: onBack)
                .navigationSplitViewColumnWidth(min: 300, ideal: 300, max: 500)
        } content: {
            SecondPanelView(viewModel: viewModel)
                .navigationTitle("")
                .navigationSplitViewColumnWidth(min: 320, ideal: 320, max: 500)
        } detail: {
            DetailPanelView(viewModel: viewModel)
                .navigationTitle("")
                .navigationSplitViewColumnWidth(min: 380, ideal: 380)
        }
        .task {
            await viewModel.handleAppear()
        }
        .onDisappear { viewModel.stopScan() }
        .onChange(of: viewModel.selectedTopFolder) {
            viewModel.selectedBigFolder = nil
        }
        .onChange(of: viewModel.bigFolders) {
            if viewModel.selectedBigFolder == nil, let first = viewModel.bigFolders.first {
                viewModel.selectedBigFolder = first
            }
        }
    }
}
