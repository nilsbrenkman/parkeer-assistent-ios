//
//  TestUtil.swift
//  parkeerassistentUITests
//
//  Created by Nils Brenkman on 07/08/2021.
//

import XCTest

/// Shared base class for the UI test suites.
///
/// Launches the app in UI-test mode and registers an interruption monitor that
/// dismisses system dialogs (most notably the "Save Password" prompt) which can
/// otherwise appear over the app at unpredictable moments and intercept taps.
class UITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        addUIInterruptionMonitor(withDescription: "System dialog") { alert in
            for label in ["Not Now", "Don't Allow", "Cancel", "Allow", "OK"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }

        app = XCUIApplication()
        app.launchEnvironment = ["RUNMODE": "uitest"]
        app.launch()
    }

}

struct TestUtil {

    static let timeout: TimeInterval = 10

    private static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    /// Dismisses the iOS "Save Password" prompt, a springboard alert that can be
    /// presented after the login form is submitted. Returns as soon as the
    /// prompt is handled, or after `timeout` if it never appears.
    static func dismissSavePasswordPrompt(timeout: TimeInterval = 3) {
        let notNow = springboard.buttons["Not Now"]
        if notNow.waitForExistence(timeout: timeout) {
            notNow.tap()
        }
    }

}

struct Label {

    static let add = Label.buildPredicate("Add")
    static let start = Label.buildPredicate("Start")

    static let username = Label.buildPredicate("Permit code")
    static let password = Label.buildPredicate("Pin code")
    static let login = Label.buildPredicate("Login")
    static let logout = Label.buildPredicate("Logout")

    // section headers are rendered uppercased by the grouped list style
    static let parkingHeader = Label.buildCaseInsensitivePredicate("Parking:")
    static let parkingEmpty = Label.buildPredicate("No active or scheduled sessions")
    static let parkingActive = Label.buildCaseInsensitivePredicate("Active sessions")
    static let parkingScheduled = Label.buildCaseInsensitivePredicate("Scheduled sessions")

    static let visitorHeader = Label.buildCaseInsensitivePredicate("Visitors:")
    static let addVisitor = Label.buildPredicate("Add visitor")

    private static func buildPredicate(_ label: String) -> NSPredicate {
        NSPredicate(format: "label CONTAINS %@", label)
    }

    private static func buildCaseInsensitivePredicate(_ label: String) -> NSPredicate {
        NSPredicate(format: "label CONTAINS[c] %@", label)
    }

}
