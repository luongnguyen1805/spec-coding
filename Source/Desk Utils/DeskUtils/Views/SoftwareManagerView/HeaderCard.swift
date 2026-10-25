import SwiftUI

struct HeaderCard: View {
    let item: SoftwareItem

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14)
                .fill(item.source.gradient)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: item.source.iconName)
                        .font(.defaultFont)
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.defaultFontBold)
                    .textSelection(.enabled)

                HStack(spacing: 8) {
                    SourceBadge(source: item.source)
                    if let version = item.version {
                        Text("v\(version)")
                            .font(.defaultFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
