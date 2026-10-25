import SwiftUI

struct SoftwareManagerView: View {
    @ObservedObject var viewModel: SoftwareViewModel
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
            DetailPanelView(item: viewModel.selectedItem, viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 380, ideal: 380)
        }
        .task {
            await viewModel.scan()
        }
    }
    
}
