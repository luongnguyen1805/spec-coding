import Foundation
import XCTest

final class DeskUtilsCaptureTests: XCTestCase {
    @MainActor
    func testLaunchAndCapture() {
        captureScreen(name: "launch")
    }

    @MainActor
    func testManageAppsAndCapture() {
        captureScreen(name: "apps", card: "dashboard.software")
    }

    @MainActor
    func testManageFoldersAndCapture() {
        captureScreen(name: "folders", card: "dashboard.folders")
    }

    @MainActor
    private func captureScreen(name: String, card: String? = nil) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }
        if let card {
            let button = app.buttons[card]
            XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing dashboard card: \(card)")
            button.click()
        }
        Thread.sleep(forTimeInterval: 1)
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "DeskUtils did not open a window")
        let screenshot = window.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
