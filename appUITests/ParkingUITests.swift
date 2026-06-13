//
//  ParkingUITests.swift
//  parkeerassistentUITests
//
//  Created by Nils Brenkman on 07/08/2021.
//

import XCTest

class ParkingUITests: UITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch(loggedIn: true)
    }

    func testNoParking() throws {
        ParkingUITests.initialParkingList(app)
    }

    func testAddParkingNow() throws {
        ParkingUITests.initialParkingList(app)
        VisitorUITests.initialVisitorList(app)

        let erik = app.buttons["22-BBB-2, Erik"]
        erik.tap()

        let wheel = app.otherElements["wheel-selector"]
        XCTAssertTrue(wheel.waitForExistence(timeout: TestUtil.timeout))
        wheel.swipeLeft()

        app.buttons.element(matching: Label.add).tap()

        ParkingUITests.numberOfParking(app, count: 1)

        let empty = app.staticTexts.element(matching: Label.parkingEmpty)
        XCTAssertFalse(empty.exists)

        let active = app.staticTexts.element(matching: Label.parkingActive)
        XCTAssertTrue(active.exists)
    }

    func testAddParkingLater() throws {
        ParkingUITests.initialParkingList(app)
        VisitorUITests.initialVisitorList(app)

        let erik = app.buttons["22-BBB-2, Erik"]
        erik.tap()

        let wheel = app.otherElements["wheel-selector"]
        XCTAssertTrue(wheel.waitForExistence(timeout: TestUtil.timeout))
        wheel.swipeLeft()

        app.staticTexts.element(matching: Label.start).tap()
        wheel.swipeLeft()

        app.buttons.element(matching: Label.add).tap()

        ParkingUITests.numberOfParking(app, count: 1)

        let empty = app.staticTexts.element(matching: Label.parkingEmpty)
        XCTAssertFalse(empty.exists)

        let scheduled = app.staticTexts.element(matching: Label.parkingScheduled)
        XCTAssertTrue(scheduled.exists)
    }

    func testStopParkingFromDetail() throws {
        addActiveParking()

        let parking = app.buttons.matching(identifier: "parking").firstMatch
        XCTAssertTrue(parking.waitForExistence(timeout: TestUtil.timeout))
        parking.tap()

        let stop = app.buttons.element(matching: Label.parkingStop)
        XCTAssertTrue(stop.waitForExistence(timeout: TestUtil.timeout))
        stop.tap()

        let header = app.staticTexts.element(matching: Label.parkingHeader)
        XCTAssertTrue(header.waitForExistence(timeout: TestUtil.timeout))

        ParkingUITests.numberOfParking(app, count: 0)
        let empty = app.staticTexts.element(matching: Label.parkingEmpty)
        XCTAssertTrue(empty.exists)
    }

    func testDeleteParkingFromList() throws {
        addActiveParking()

        let parking = app.buttons.matching(identifier: "parking").firstMatch
        XCTAssertTrue(parking.waitForExistence(timeout: TestUtil.timeout))
        parking.tap()

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: TestUtil.timeout))
        backButton.tap()

        let header = app.staticTexts.element(matching: Label.parkingHeader)
        XCTAssertTrue(header.waitForExistence(timeout: TestUtil.timeout))

        let session = app.buttons.matching(identifier: "parking").firstMatch
        XCTAssertTrue(session.waitForExistence(timeout: TestUtil.timeout))
        session.swipeLeft()

        let delete = app.buttons["delete-parking"]
        XCTAssertTrue(delete.waitForExistence(timeout: TestUtil.timeout))
        delete.tap()

        ParkingUITests.numberOfParking(app, count: 0)
        let empty = app.staticTexts.element(matching: Label.parkingEmpty)
        XCTAssertTrue(empty.exists)
    }

    private func addActiveParking() {
        ParkingUITests.initialParkingList(app)
        VisitorUITests.initialVisitorList(app)

        let erik = app.buttons["22-BBB-2, Erik"]
        erik.tap()

        let wheel = app.otherElements["wheel-selector"]
        XCTAssertTrue(wheel.waitForExistence(timeout: TestUtil.timeout))
        wheel.swipeLeft()

        app.buttons.element(matching: Label.add).tap()

        ParkingUITests.numberOfParking(app, count: 1)
    }

    static func initialParkingList(_ app: XCUIApplication) {
        let header = app.staticTexts.element(matching: Label.parkingHeader)
        XCTAssertTrue(header.waitForExistence(timeout: TestUtil.timeout))

        let empty = app.staticTexts.element(matching: Label.parkingEmpty)
        XCTAssertTrue(empty.waitForExistence(timeout: TestUtil.timeout))
    }

    static func numberOfParking(_ app: XCUIApplication, count: Int) {
        let visitor = app.buttons.matching(identifier: "parking")
        let predicate = NSPredicate(format: "count == \(count)")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: visitor)
        let result = XCTWaiter().wait(for: [expectation], timeout: TestUtil.timeout)
        XCTAssertEqual(.completed, result)
    }

}
