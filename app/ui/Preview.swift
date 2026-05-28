//
//  Preview.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 17/02/2022.
//

import SwiftUI

#if DEBUG
    private enum PreviewSetup {
        static let registerClients: Void = {
            ClientManager.instance.register(LoginClient.self, client: LoginClientApi.client)
            ClientManager.instance.register(UserClient.self, client: UserClientApi.client)
            ClientManager.instance.register(ParkingClient.self, client: ParkingClientApi.client)
            ClientManager.instance.register(VisitorClient.self, client: VisitorClientApi.client)
            ClientManager.instance.register(PaymentClient.self, client: PaymentClientApi.client)
            ClientManager.instance.register(GeoClient.self, client: GeoClientApi.client)
        }()
    }

    extension View {

        @MainActor func setupPreview(loggedIn: Bool = false) -> some View {
            _ = PreviewSetup.registerClients
            let session = SessionStore()
            session.isLoggedIn = loggedIn
            let accounts = AccountStore()
            let user = UserStore()
            let visitors = VisitorStore()
            let parkings = ParkingStore()
            let parkingMeter = ParkingMeterStore()
            let payment = PaymentStore()
            let router = Router()
            let messages = MessageStore.shared
            return environmentObject(session)
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
#endif
