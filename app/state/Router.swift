//
//  Router.swift
//  parkeerassistent
//

import Foundation
import SwiftUI

enum Screen: Hashable {
    case login
    case user
    case info
    case history
    case payment
    case accounts
    case account(Credentials)
    case settings
    case addVisitor
    case addParking(Visitor)
    case parkingDetail(Parking)
}

@MainActor
class Router: ObservableObject {

    @Published var path: [Screen] = []

    func pushScreen(_ screen: Screen) {
        path.append(screen)
    }

    func popScreen() {
        _ = path.popLast()
    }

    func setRoot(_ screens: [Screen]) {
        path = screens
    }

    func reset() {
        path = []
    }

    func syncRoot(isLoggedIn: Bool, isLoading: Bool, isBackground: Bool) {
        if isLoading || isBackground {
            path = []
        } else if isLoggedIn {
            path = [.user]
        } else {
            path = [.login]
        }
    }

}
