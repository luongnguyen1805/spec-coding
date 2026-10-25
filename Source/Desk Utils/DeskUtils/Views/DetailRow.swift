import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.defaultFont)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.defaultFont)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
