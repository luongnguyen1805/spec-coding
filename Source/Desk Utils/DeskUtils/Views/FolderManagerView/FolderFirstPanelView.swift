import SwiftUI

extension FolderManagerView {
    struct FirstPanelView: View {
        @ObservedObject var viewModel: ManageFoldersViewModel
        let onBack: () -> Void

        var body: some View {
            VStack(spacing: 0) {
                PanelTopBar(
                    onBack: onBack,
                    isScanning: viewModel.isScanning,
                    onRefresh: { viewModel.startScan() },
                    refreshHelp: "Re-scan folders"
                )
                Divider().padding(.vertical, 8)
                List(selection: $viewModel.selectedTopFolder) {
                    Section("Drives") {
                        ForEach(viewModel.topFolders, id: \.sizeRefreshID) { folder in
                            DriveRowView(folder: folder)
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: folder.path)])
                                }
                                .onTapGesture(count: 1) {
                                    viewModel.selectedTopFolder = folder
                                }
                                .tag(folder)
                        }
                    }
                }
                .listStyle(.sidebar)
                .onAppear {
                    if viewModel.selectedTopFolder == nil {
                        viewModel.selectedTopFolder = viewModel.topFolders.first
                    }
                }
                .onChange(of: viewModel.topFolders) {
                    if viewModel.selectedTopFolder == nil {
                        viewModel.selectedTopFolder = viewModel.topFolders.first
                    }
                }
            }
            .navigationTitle("Folder Manager")
        }
    }
}

private struct DriveRowView: View {
    let folder: FolderItem

    var body: some View {
        HStack {
            Image(systemName: "internaldrive")
                .foregroundStyle(.secondary)
            Text(folder.name)
                .lineLimit(1)
                .font(.defaultFont)
            Spacer()
            Text(ViewUtils.formattedFolderSummary(fileCount: folder.fileCount, sizeBytes: folder.sizeBytes))
                .font(.defaultFont.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.all, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
