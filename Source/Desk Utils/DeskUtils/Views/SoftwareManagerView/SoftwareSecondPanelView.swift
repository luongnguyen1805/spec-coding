import SwiftUI

extension SoftwareManagerView {
    struct SecondPanelView: View {
        @ObservedObject var viewModel: SoftwareViewModel

        var body: some View {
            
            HStack {
                Text(viewModel.selectedCategory?.rawValue ?? "All Items")
                    .lineLimit(1)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(countText)
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.all, 20)
            .frame(maxWidth: .infinity, alignment: .leading)

            List(viewModel.filteredItems, selection: $viewModel.selectedItem) { item in
                AppRowView(item: item)
                    .tag(item)
            }
            .listStyle(.sidebar)
            //.searchable(text: $viewModel.searchText, placement: .sidebar, prompt: searchPrompt)
            //.overlay { overlayContent }
        }

//        @ViewBuilder
//        private var overlayContent: some View {
//            if viewModel.filteredItems.isEmpty {
//                ContentUnavailableView(
//                    emptyTitle,
//                    systemImage: "magnifyingglass",
//                    description: Text(
//                        viewModel.searchText.isEmpty
//                            ? emptyScanDescription
//                            : "No results for \"\(viewModel.searchText)\"."
//                    )
//                )
//            }
//        }

        // MARK: - Contextual Terminology

//        private var searchPrompt: String {
//            guard let category = viewModel.selectedCategory else { return "Search items…" }
//            return "Search \(category.localizedItemNoun)"
//        }

//        private var emptyTitle: String {
//            guard let category = viewModel.selectedCategory else { return "No Items Found" }
//            return "No \(category.localizedItemNoun)s Found"
//        }

//        private var emptyScanDescription: String {
//            guard let category = viewModel.selectedCategory else { return "Scan to load items." }
//            return "Scan to load \(category.localizedItemNoun.lowercased())s."
//        }
        
        private var countText: String {
            let count = viewModel.filteredItems.count
            return "\(count) \(count == 1 ? "item" : "items")"
        }
    }
}

struct AppRowView: View {
    let item: SoftwareItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.source.iconName)
                .foregroundStyle(item.source.tintColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15))
                    .lineLimit(1)
                if let version = item.version {
                    Text("v\(version)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
