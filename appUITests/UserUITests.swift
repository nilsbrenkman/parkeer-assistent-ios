//
//  UserUITests.swift
//  parkeerassistentUITests
//
//  Created by Nils Brenkman on 04/08/2021.
//

import XCTest

class UserUITests: UITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        LoginUITests.login(app, usernameInput: "test", passwordInput: "1234")
    }

    func testBalance() throws {
        let saldo = app.staticTexts["Balance:"]
        XCTAssertTrue(saldo.waitForExistence(timeout: TestUtil.timeout))

        XCTAssertEqual(10.00, UserUITests.getBalance(app))
    }

    static func getBalance(_ app: XCUIApplication) -> Double {
        let balance = app.staticTexts["balance"]
        XCTAssertTrue(balance.exists)

        let formatted = balance.label
        let amount = formatted.dropFirst(2)
        return Double(amount) ?? 0
    }

}
