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

        let playButton = app.buttons["playButton"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 6))
        playButton.tap()

        XCTAssertTrue(app.staticTexts["gameScore"].waitForExistence(timeout: 5))

        let gameSurface = app.otherElements["gameSurface"]
        XCTAssertTrue(gameSurface.waitForExistence(timeout: 3))

        let start = gameSurface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
        let end = gameSurface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
        start.press(forDuration: 0.08, thenDragTo: end)

        XCTAssertTrue(app.staticTexts["gameScore"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApp().launch()
        }
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_MODE"]
        return app
    }
}
