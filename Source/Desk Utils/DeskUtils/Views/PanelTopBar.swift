import SwiftUI

struct PanelTopBar: View {
    let onBack: () -> Void
    let isScanning: Bool
    let onRefresh: () -> Void
    let refreshHelp: String

    var body: some View {
        HStack {
            Button(action: onBack) {
                Label("Dashboard", systemImage: "arrow.left")
            }
            .buttonStyle(.plain)

            Spacer()

            if isScanning {
                ProgressView()
                    .controlSize(.small)
                    .help("Scanning in progress…")
            } else {
                Button(action: onRefresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help(refreshHelp)
            }
        }
        .font(.defaultFont)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
