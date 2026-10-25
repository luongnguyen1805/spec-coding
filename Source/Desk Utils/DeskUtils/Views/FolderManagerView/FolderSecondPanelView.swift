import SwiftUI

extension FolderManagerView {
    struct SecondPanelView: View {
        @ObservedObject var viewModel: ManageFoldersViewModel

        var body: some View {
            Group {
                if viewModel.selectedTopFolder == nil {
                    ContentUnavailableView("Select a Drive", systemImage: "internaldrive")
                } else if viewModel.bigFolders.isEmpty && !viewModel.isScanning {
                    ContentUnavailableView("No Folders", systemImage: "folder")
                } else {
                    HStack {
                        Text(viewModel.selectedTopFolder!.name)
                            .lineLimit(1)
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Text(countText)
                            .font(.system(size: 13).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.all, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    List(selection: $viewModel.selectedBigFolder) {
                        ForEach(viewModel.bigFolders, id: \.sizeRefreshID) { folder in
                            BigFolderRowView(folder: folder)
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: folder.path)])
                                }
                                .onTapGesture(count: 1) {
                                    viewModel.selectedBigFolder = folder
                                }
                                .tag(folder)
                        }
                    }
                }
            }
        }
        
        var countText: String {
            let count = viewModel.bigFolders.count
            return "\(count) \(count == 1 ? "folder" : "folders")"
        }

    }
    
}

private struct BigFolderRowView: View {
    let folder: FolderItem

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.yellow)
            Text(folder.name)
                .lineLimit(1)
                .font(.system(size: 15))
            Spacer()
            Text(ViewUtils.formattedFolderSummary(fileCount: folder.fileCount, sizeBytes: folder.sizeBytes))
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.all, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
