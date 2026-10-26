import SwiftUI

@MainActor
struct RevealInFinderButton: View {
    let item: SoftwareItem
    let viewModel: SoftwareViewModel

    @State private var isLocating = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Button {
            Task { 
                await revealInFinder()
            }
        } label: {
            HStack(spacing: 4) {
                if isLocating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "arrow.right.circle")
                        .font(.defaultFont)
                }
            }
        }
        .disabled(isLocating || item.installPath == nil)
        .buttonStyle(.borderless)
        .accessibilityLabel("Reveal \(item.name) in Finder")
        .help(helpText)
        .alert("Cannot Locate Folder", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var helpText: String {
        if isLocating {
            return "Locating package directory..."
        }
        if item.installPath == nil {
            return "No path available"
        }
        return "Show in Finder"
    }

    // MARK: - Reveal Logic
    private func revealInFinder() async {
        isLocating = true
        defer { isLocating = false }

        guard let resolvedPath = await resolvePackagePath() else {
            errorMessage = "Unable to locate source folder for \(item.name)."
            showError = true
            return
        }

        let url = URL(fileURLWithPath: resolvedPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "Unable to locate source folder for \(item.name)."
            showError = true
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func resolvePackagePath() async -> String? {
        await viewModel.resolveInstallPath(for: item)
    }
}
