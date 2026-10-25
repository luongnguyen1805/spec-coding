import SwiftUI

extension SoftwareManagerView {
    struct FirstPanelView: View {
        @ObservedObject var viewModel: SoftwareViewModel
        let onBack: () -> Void

        var body: some View {
            VStack(spacing: 0) {
                PanelTopBar(
                    onBack: onBack,
                    isScanning: viewModel.isScanning,
                    onRefresh: { viewModel.startScan() },
                    refreshHelp: "Re-scan installed applications"
                )
                Divider()
                List {
                    Section("Categories") {
                        ForEach(SoftwareSource.allCases, id: \.self) { source in
                            SidebarRow(source: source, count: viewModel.itemCount(for: source))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedCategory = source
                                }
                                .listRowBackground(
                                    viewModel.selectedCategory == source
                                        ? Color.gray.opacity(0.15)
                                        : Color.clear
                                )
                        }
                    }

                    if !viewModel.scanErrors.isEmpty {
                        Section("Warnings") {
                            ForEach(viewModel.scanErrors, id: \.self) { msg in
                                Label(msg, systemImage: "exclamationmark.triangle.fill")
                                    .font(.defaultFont)
                                    .foregroundStyle(.orange)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationTitle("Application Manager")
        }
    }
}

private struct SidebarRow: View {
    let source: SoftwareSource
    let count: Int

    var body: some View {
        HStack {
            Label(source.rawValue, systemImage: source.iconName)
                .foregroundStyle(.primary)
                .font(.defaultFont)
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.defaultFont.monospacedDigit())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.18))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
