import SwiftUI

struct DetailsCard: View {
    let item: SoftwareItem
    let viewModel: SoftwareViewModel

    var body: some View {
        CardContainer(title: "Details") {
            DetailRow(label: "\(item.source.localizedItemNoun) Name", value: item.name)
            DetailRow(label: "Source", value: item.source.rawValue)
            if let version = item.version {
                DetailRow(label: "Version", value: version)
            }
            if let path = item.installPath {
                DetailRow(label: "Install Path", value: path)
                RevealInFinderButton(item: item, viewModel: viewModel)
                    .padding(.top, 4)
            }
            if let desc = item.description {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    Text(desc)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
