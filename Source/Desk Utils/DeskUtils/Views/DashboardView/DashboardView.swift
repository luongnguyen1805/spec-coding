import SwiftUI

struct DashboardView: View {
    @Binding var showSoftwareManager: Bool
    @Binding var showFolderManager: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Desktop Utilities")
                .font(.defaultFontBold)
                .padding(24)

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
                DashboardCard(
                    title: "Manage Folders",
                    subtitle: "",
                    icon: "internaldrive.fill",
                    color: .orange
                ) {
                    showFolderManager = true
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
