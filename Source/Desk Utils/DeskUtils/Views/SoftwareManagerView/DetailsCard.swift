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
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Install Path")
                            .font(.defaultFont)
                            .foregroundStyle(.secondary)
                        RevealInFinderButton(item: item, viewModel: viewModel)
                    }
                    Text(path)
                        .font(.defaultFont)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let desc = item.description {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.defaultFont)
                        .foregroundStyle(.secondary)
                    Text(desc)
                        .font(.defaultFont)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
