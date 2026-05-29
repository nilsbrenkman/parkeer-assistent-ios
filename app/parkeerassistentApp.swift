//
//  parkeerassistentApp.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 12/06/2021.
//

import SwiftUI

@main
struct parkeerassistentApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var session = SessionStore(loginClient: LoginClientApi.client)
    @StateObject var accounts = AccountStore()
    @StateObject var user = UserStore(userClient: UserClientApi.client)
    @StateObject var visitors = VisitorStore(visitorClient: VisitorClientApi.client)
    @StateObject var parkings = ParkingStore(parkingClient: ParkingClientApi.client)
    @StateObject var parkingMeter = ParkingMeterStore(geoClient: GeoClientApi.client)
    @StateObject var payment = PaymentStore(paymentClient: PaymentClientApi.client)
    @StateObject var router = Router()
    @StateObject var messages = MessageStore.shared

    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
    }

    var body: some Scene {

        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(accounts)
                .environmentObject(user)
                .environmentObject(visitors)
                .environmentObject(parkings)
                .environmentObject(parkingMeter)
                .environmentObject(payment)
                .environmentObject(router)
                .environmentObject(messages)
        }
    }

}
