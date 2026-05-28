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

    @StateObject var app = AppModel()
    @StateObject var user = UserModel()
    @StateObject var messenger = AppMessenger()

    init() {
        ClientManager.instance.register(LoginClient.self,   client: LoginClientApi.client)
        ClientManager.instance.register(UserClient.self,    client: UserClientApi.client)
        ClientManager.instance.register(ParkingClient.self, client: ParkingClientApi.client)
        ClientManager.instance.register(VisitorClient.self, client: VisitorClientApi.client)
        ClientManager.instance.register(PaymentClient.self, client: PaymentClientApi.client)
        ClientManager.instance.register(GeoClient.self,     client: GeoClientApi.client)

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
                .environmentObject(app)
                .environmentObject(user)
                .environmentObject(messenger)
        }
    }

}
