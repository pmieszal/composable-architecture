import XCTest

class PrimeTimeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTS"] = "1"
        app.launch()
        app.tables.buttons["Counter demo"].tap()

        let button = app.buttons["+"]
        button.tap()
        button.tap()
        app.buttons["What is the 2nd prime?"].tap()
        
        let alert = app.alerts["The 2nd prime is 3"]
        XCTAssert(alert.waitForExistence(timeout: 5))
        
        alert.scrollViews.otherElements.buttons["Ok"].tap()
        
        app.buttons["Is this prime?"].tap()
        app.buttons["Add to favorite primes"].tap()
        
        app
            .children(matching: .window)
            .element(boundBy: 0)
            .children(matching: .other)
            .element.children(matching: .other)
            .element(boundBy: 0)
            .swipeDown()
    }
}
