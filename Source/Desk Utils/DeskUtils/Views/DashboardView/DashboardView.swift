import SwiftUI

struct DashboardView: View {
    @Binding var showSoftwareManager: Bool
    @Binding var showFolderManager: Bool
    @Binding var showFolderSync: Bool

    private let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Desktop Utilities"
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(appName)
                    .font(.defaultFontBold)
                if let appVersion {
                    Text("v\(appVersion)")
                        .font(.defaultFont)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .accessibilityIdentifier("dashboard.header")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)]
                      , spacing: 16) {
                DashboardCard(
                    title: "Manage Applications and Packages",
                    subtitle: "",
                    icon: "shippingbox.fill",
                    color: .blue
                ) {
                    showSoftwareManager = true
                }
                .accessibilityIdentifier("dashboard.software")
                DashboardCard(
                    title: "Manage Folders",
                    subtitle: "",
                    icon: "internaldrive.fill",
                    color: .orange
                ) {
                    showFolderManager = true
                }
                .accessibilityIdentifier("dashboard.folders")
                DashboardCard(
                    title: "Folder Sync",
                    subtitle: "",
                    icon: "arrow.left.arrow.right",
                    color: .green
                ) {
                    showFolderSync = true
                }
                .accessibilityIdentifier("dashboard.folderSync")
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
