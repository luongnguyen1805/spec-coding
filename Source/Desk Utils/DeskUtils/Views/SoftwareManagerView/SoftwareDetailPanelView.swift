import SwiftUI

extension SoftwareManagerView {
    struct DetailPanelView: View {
        let item: SoftwareItem?
        let viewModel: SoftwareViewModel

        var body: some View {
            if let item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HeaderCard(item: item)
                        DetailsCard(item: item, viewModel: viewModel)
                        if let deps = item.dependencies, !deps.isEmpty {
                            DependenciesCard(deps: deps)
                        }
                        if let metadata = item.metadata, !metadata.isEmpty {
                            MetadataCard(metadata: metadata)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "shippingbox",
                    description: Text("Choose an item from the list to view its details.")
                )
            }
        }
    }
}
