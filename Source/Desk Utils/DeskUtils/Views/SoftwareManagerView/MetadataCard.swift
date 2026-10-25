import SwiftUI

struct MetadataCard: View {
    let metadata: [String: String]

    var body: some View {
        CardContainer(title: "Metadata") {
            ForEach(metadata.keys.sorted(), id: \.self) { key in
                if let value = metadata[key] {
                    DetailRow(label: key.capitalized, value: value)
                }
            }
        }
    }
}
