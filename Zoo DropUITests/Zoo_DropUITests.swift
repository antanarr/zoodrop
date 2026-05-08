//
//  Zoo_DropUITests.swift
//  Zoo DropUITests
//
//  Created by Anthony Yarand on 7/3/25.
//

import XCTest

final class Zoo_DropUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = makeApp()
        app.launch()

        assertHomeDockVisible(in: app)

        let playButton = app.buttons["playButton"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 6))
        playButton.tap()

        XCTAssertTrue(app.staticTexts["gameScore"].waitForExistence(timeout: 5))
        let nudgeButton = app.buttons["nudgePowerButton"]
        let nextAnimalPanel = app.buttons["nextAnimalPanel"]
        let rerollButton = app.buttons["rerollPowerButton"]
        XCTAssertTrue(nudgeButton.waitForExistence(timeout: 3))
        XCTAssertTrue(nudgeButton.isHittable)
        XCTAssertTrue(nextAnimalPanel.waitForExistence(timeout: 3))
        XCTAssertTrue(nextAnimalPanel.isHittable)
        XCTAssertTrue(rerollButton.waitForExistence(timeout: 3))
        XCTAssertTrue(rerollButton.isHittable)
        assertFullyVisible(nudgeButton, in: app)
        assertFullyVisible(nextAnimalPanel, in: app)
        assertFullyVisible(rerollButton, in: app)
        XCTAssertFalse(nextAnimalPanel.frame.intersects(nudgeButton.frame))
        XCTAssertFalse(nextAnimalPanel.frame.intersects(rerollButton.frame))

        let gameSurface = app.otherElements["gameSurface"]
        XCTAssertTrue(gameSurface.waitForExistence(timeout: 3))

        let start = gameSurface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
        let end = gameSurface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
        start.press(forDuration: 0.08, thenDragTo: end)

        XCTAssertTrue(app.staticTexts["gameScore"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testFirstRunPrivacyAndOnboardingControlsStayVisible() throws {
        let app = makeApp(extraLaunchArguments: ["UITEST_FIRST_RUN"])
        app.launch()

        let privacyContinueButton = app.buttons["privacyContinueButton"]
        XCTAssertTrue(privacyContinueButton.waitForExistence(timeout: 6))
        XCTAssertTrue(privacyContinueButton.isHittable)
        assertFullyVisible(privacyContinueButton, in: app)
        privacyContinueButton.tap()

        let onboardingStartButton = app.buttons["onboardingStartButton"]
        XCTAssertTrue(onboardingStartButton.waitForExistence(timeout: 6))
        XCTAssertTrue(onboardingStartButton.isHittable)
        assertFullyVisible(onboardingStartButton, in: app)
        onboardingStartButton.tap()

        XCTAssertTrue(app.buttons["playButton"].waitForExistence(timeout: 6))
        assertHomeDockVisible(in: app)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApp().launch()
        }
    }

    private func makeApp(extraLaunchArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_MODE"] + extraLaunchArguments
        return app
    }

    @MainActor
    private func assertHomeDockVisible(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let dockIdentifiers = [
            "homeDock-scores",
            "homeDock-daily",
            "homeDock-howToPlay",
            "homeDock-shop",
            "homeDockMoreButton"
        ]

        for identifier in dockIdentifiers {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.waitForExistence(timeout: 6), "Missing \(identifier)", file: file, line: line)
            XCTAssertTrue(button.isHittable, "\(identifier) is not hittable", file: file, line: line)
            assertFullyVisible(button, in: app, file: file, line: line)
        }
    }

    @MainActor
    private func assertFullyVisible(_ element: XCUIElement, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(element.frame.isEmpty, "Element has an empty frame", file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.frame.minX, file: file, line: line)
        XCTAssertGreaterThanOrEqual(element.frame.minY, app.frame.minY, file: file, line: line)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.frame.maxX, file: file, line: line)
        XCTAssertLessThanOrEqual(element.frame.maxY, app.frame.maxY, file: file, line: line)
    }
}
