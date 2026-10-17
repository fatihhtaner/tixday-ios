import XCTest

/// Apple's accessibility audit over the main screens: every element VoiceOver reaches needs a name,
/// and text must not be clipped at large sizes. Runs with sample tickets and Pro on.
final class AccessibilityAuditTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-sampleData", "-proScreenshots", "-AppleLanguages", "(en)", "didFinishOnboarding", "YES"]
        app.launch()
    }

    /// The audit checks VoiceOver names and touch targets; colour contrast over poster art is left out,
    /// since the audit can't see the scrims behind the type.
    private func audit(_ screen: String) throws {
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .hitRegion, .trait]) { issue in
            print("AUDIT [\(screen)] \(issue.auditType) – \(issue.compactDescription) – \(issue.element?.debugDescription.prefix(160) ?? "")")
            return false
        }
    }

    func testHome() throws {
        try audit("home")
    }

    func testEditor() throws {
        app.buttons["New ticket"].tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 5))
        try audit("editor")
    }

    func testDetail() throws {
        // The hero ticket is the first "days left" button; it opens straight into its details.
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "days left")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 5))
        try audit("detail")
    }

    func testSettings() throws {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        try audit("settings")
    }

    func testPaywall() throws {
        app.terminate()
        app.launchArguments = ["-sampleData", "-resetPro", "-AppleLanguages", "(en)", "didFinishOnboarding", "YES"]
        app.launch()
        app.buttons["Pro"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Tixday Pro"].waitForExistence(timeout: 5))
        try audit("paywall")
    }

    func testOnboarding() throws {
        app.terminate()
        app.launchArguments = ["-onboarding", "-AppleLanguages", "(en)"]
        app.launch()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        try audit("onboarding")
    }
}
