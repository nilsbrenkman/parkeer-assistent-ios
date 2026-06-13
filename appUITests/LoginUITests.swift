//
//  LoginUITests.swift
//  parkeerassistentUITests
//
//  Created by Nils Brenkman on 03/08/2021.
//

import XCTest

class LoginUITests: UITestCase {

    func testLoginScreen() throws {
        launch()

        XCTAssertTrue(app.staticTexts.element(matching: Label.username).exists)
        XCTAssertTrue(app.staticTexts.element(matching: Label.password).exists)

        let username = app.textFields["username"]
        let password = app.secureTextFields["password"]
        XCTAssertTrue(username.exists)
        XCTAssertTrue(password.exists)

        XCTAssertTrue(app.buttons.element(matching: Label.login).exists)
    }

    func testLoginSuccess() throws {
        launch()

        LoginUITests.login(app, usernameInput: "test", passwordInput: "1234")

        // The test finishes as soon as login succeeds: asserting the menu only
        // checks for existence (not a tap), so the trailing "Save Password"
        // prompt cannot interrupt it.
        let menu = app.images["menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: TestUtil.timeout))
    }

    func testLoginFailed() throws {
        launch()

        LoginUITests.login(app, usernameInput: "fail", passwordInput: "invalid")

        let message = app.staticTexts["message"]
        XCTAssertTrue(message.waitForExistence(timeout: TestUtil.timeout))
        XCTAssertTrue(message.label == "Login failed")
    }

    func testLogout() throws {
        // Start already logged in so logging out — which interacts with the
        // app after login — is never interrupted by the "Save Password" prompt
        // that a form-based login would trigger.
        launch(loggedIn: true)

        // The Image carries the "menu" identifier but is wrapped in SwiftUI's
        // Menu, whose button consumes hit-testing — the image reports
        // isHittable == false. Tap via coordinate so the touch reaches the
        // wrapping button.
        let menu = app.images["menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: TestUtil.timeout))
        menu.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let logout = app.buttons.element(matching: Label.logout)
        XCTAssertTrue(logout.waitForExistence(timeout: TestUtil.timeout))
        logout.tap()

        let username = app.staticTexts.element(matching: Label.username)
        XCTAssertTrue(username.waitForExistence(timeout: TestUtil.timeout))
        XCTAssertFalse(logout.exists)
    }

    static func login(_ app: XCUIApplication, usernameInput: String, passwordInput: String) {
        let username = app.textFields["username"]
        XCTAssertTrue(username.waitForExistence(timeout: TestUtil.timeout))
        username.tap()
        username.typeText(usernameInput)

        let password = app.secureTextFields["password"]
        password.tap()
        password.typeText(passwordInput)

        let login = app.buttons.element(matching: Label.login)
        login.tap()

        // Clear the iOS "Save Password" prompt if it appears. A prompt that
        // appears later is handled by the interruption monitor registered in
        // UITestCase on the next interaction with the app.
        TestUtil.dismissSavePasswordPrompt()
    }

}
