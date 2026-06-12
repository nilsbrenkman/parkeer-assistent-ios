//
//  TestUtil.swift
//  parkeerassistentUITests
//
//  Created by Nils Brenkman on 07/08/2021.
//

import Foundation

struct TestUtil {

    static let timeout: TimeInterval = 10

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

    static let dismiss = Label.buildPredicate("Not Now")

    private static func buildPredicate(_ label: String) -> NSPredicate {
        NSPredicate(format: "label CONTAINS %@", label)
    }

    private static func buildCaseInsensitivePredicate(_ label: String) -> NSPredicate {
        NSPredicate(format: "label CONTAINS[c] %@", label)
    }

}
