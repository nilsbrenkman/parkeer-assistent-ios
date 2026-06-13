//
//  VisitorUITests.swift
//  parkeerassistentUITests
//
//  Created by Nils Brenkman on 04/08/2021.
//

import XCTest

class VisitorUITests: UITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch(loggedIn: true)
    }

    func testVisitorList() throws {
        VisitorUITests.initialVisitorList(app)
    }

    func testAddVisitor() throws {
        VisitorUITests.initialVisitorList(app)

        let addVisitor = app.buttons.element(matching: Label.addVisitor)
        XCTAssertTrue(addVisitor.waitForExistence(timeout: TestUtil.timeout))
        addVisitor.tap()

        let license = app.textFields["license"]
        XCTAssertTrue(license.waitForExistence(timeout: TestUtil.timeout))
        let name = app.textFields["name"]
        XCTAssertTrue(name.waitForExistence(timeout: TestUtil.timeout))

        license.tap()
        license.typeText("99zz99")
        name.tap()
        name.typeText("New visitor")

        app.buttons["Add"].tap()

        VisitorUITests.numberOfVisitors(app, count: 5)
    }

    func testDeleteVisitor() throws {
        try testVisitorList()

        let erik = app.buttons["22-BBB-2, Erik"]
        erik.swipeLeft()

        let delete = app.buttons["delete-visitor"]
        XCTAssertTrue(delete.waitForExistence(timeout: TestUtil.timeout))
        delete.tap()

        VisitorUITests.numberOfVisitors(app, count: 3)
    }

    static func initialVisitorList(_ app: XCUIApplication) {
        let header = app.staticTexts.element(matching: Label.visitorHeader)
        XCTAssertTrue(header.waitForExistence(timeout: TestUtil.timeout))

        VisitorUITests.numberOfVisitors(app, count: 4)
    }

    static func numberOfVisitors(_ app: XCUIApplication, count: Int) {
        let visitor = app.buttons.matching(identifier: "visitor")
        let predicate = NSPredicate(format: "count == \(count)")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: visitor)
        let result = XCTWaiter().wait(for: [expectation], timeout: TestUtil.timeout)
        XCTAssertEqual(.completed, result)
    }

}
