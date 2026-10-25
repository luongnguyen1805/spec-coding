import SwiftUI

@main
struct DeskUtilsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1200, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
