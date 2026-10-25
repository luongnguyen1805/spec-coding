import SwiftUI

struct SourceBadge: View {
    let source: SoftwareSource

    var body: some View {
        Text(source.rawValue)
            .font(.system(size: 15, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(source.tintColor.opacity(0.15))
            .foregroundStyle(source.tintColor)
            .clipShape(Capsule())
    }
}
