import SwiftUI

extension FolderManagerView {
    struct DetailPanelView: View {
        private static let largeFolderThresholdBytes: Int64 = 100 * 1024 * 1024

        @ObservedObject var viewModel: ManageFoldersViewModel
        @State private var expandedFolderIDs: Set<FolderItem.ID> = []
        @State private var selectedFolderID: FolderItem.ID?
        @State private var showOnlyLargeFolders = false

        private var displayedSubFolders: [FolderItem] {
            showOnlyLargeFolders
                ? filteredBySize(viewModel.subFolders, minBytes: Self.largeFolderThresholdBytes)
                : viewModel.subFolders
        }
        
        var body: some View {
            Group {
                if let item = viewModel.selectedBigFolder {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            CardContainer(title: item.name) {
                                DetailRow(label: "Path", value: item.path)
                                DetailRow(label: "Size", value: ViewUtils.formattedFolderSummary(fileCount: item.fileCount, sizeBytes: item.sizeBytes))
                            }
                            .id(item.sizeRefreshID)
                            
                            CardContainer(title: "Folders") {
                                Toggle("Only show folders ≥ 100 MB", isOn: $showOnlyLargeFolders)
                                    .font(.defaultFont)
                                    .toggleStyle(.checkbox)
                                FolderTreeView(
                                    folders: displayedSubFolders,
                                    expandedFolderIDs: $expandedFolderIDs,
                                    selectedFolderID: $selectedFolderID
                                ).id("\(item.sizeRefreshID) - \( showOnlyLargeFolders ? "large" : "regular")")
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ContentUnavailableView("Select a Folder", systemImage: "folder.fill")
                }
            }
        }

        private func filteredBySize(_ folders: [FolderItem], minBytes: Int64) -> [FolderItem] {
            folders.compactMap { folder in
                guard folder.sizeBytes >= minBytes else { return nil }
                var kept = folder
                let filteredChildren = filteredBySize(Array(folder.childs.values), minBytes: minBytes)
                kept.childs = Dictionary(uniqueKeysWithValues: filteredChildren.map { ($0.name, $0) })
                return kept
            }
        }
    }
}

private struct FolderTreeView: View {
    let folders: [FolderItem]
    @Binding var expandedFolderIDs: Set<FolderItem.ID>
    @Binding var selectedFolderID: FolderItem.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(folders, id: \.id) { folder in
                FolderTreeRow(
                    folder: folder,
                    depth: 0,
                    expandedFolderIDs: $expandedFolderIDs,
                    selectedFolderID: $selectedFolderID
                )
            }
        }
    }
}

private struct FolderTreeRow: View {
    // Depth step is applied via this single mechanism only. `DisclosureGroup`'s
    // automatic macOS style also indents disclosed content and offsets the label
    // from its chevron by amounts that can't be measured through static analysis
    // and would compound with this padding across nesting levels, so the chevron
    // is drawn manually below (in `disclosureControl`) instead of relying on
    // `DisclosureGroup`'s built-in layout.
    private static let indentationPerDepth: CGFloat = 18
    private static let disclosureColumnWidth: CGFloat = 14

    let folder: FolderItem
    let depth: Int
    @Binding var expandedFolderIDs: Set<FolderItem.ID>
    @Binding var selectedFolderID: FolderItem.ID?

    private var sortedChildren: [FolderItem] {
        folder.sortedChilds
    }

    private var isExpanded: Bool {
        expandedFolderIDs.contains(folder.id)
    }

    private var isSelected: Bool {
        folder.id == selectedFolderID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            rowContent
            if isExpanded {
                ForEach(sortedChildren, id: \.id) { child in
                    FolderTreeRow(
                        folder: child,
                        depth: depth + 1,
                        expandedFolderIDs: $expandedFolderIDs,
                        selectedFolderID: $selectedFolderID
                    )
                }
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 4) {
            disclosureControl
            Image(systemName: "folder.fill")
                .foregroundStyle(.yellow)
            Text(folder.name)
                .lineLimit(1)
                .font(.defaultFont)
            Spacer()
            Text(ViewUtils.formattedFolderSummary(fileCount: folder.fileCount, sizeBytes: folder.sizeBytes))
                .font(.defaultFont.monospacedDigit())
                .foregroundStyle(.secondary)
                .id(folder.sizeRefreshID)
        }
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .padding(.leading, 6 + CGFloat(depth) * Self.indentationPerDepth)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.gray.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: folder.path)])
        }
        .onTapGesture(count: 1) {
            selectedFolderID = folder.id
            guard !sortedChildren.isEmpty else { return }
            toggleExpanded()
        }
    }

    // Reserves the same leading width whether or not a chevron is drawn, so
    // leaf-row and expandable-row icon/text line up at every depth.
    @ViewBuilder
    private var disclosureControl: some View {
        if sortedChildren.isEmpty {
            Color.clear
                .frame(width: Self.disclosureColumnWidth, height: 1)
        } else {
            Button(action: toggleExpanded) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.defaultFontBold)
                    .foregroundStyle(.secondary)
                    .frame(width: Self.disclosureColumnWidth, alignment: .center)
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleExpanded() {
        if isExpanded {
            expandedFolderIDs.remove(folder.id)
        } else {
            expandedFolderIDs.insert(folder.id)
        }
    }
}
