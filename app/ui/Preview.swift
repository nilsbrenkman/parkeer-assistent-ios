//
//  Preview.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 17/02/2022.
//

import SwiftUI

#if DEBUG
    extension View {

        @MainActor func setupPreview(loggedIn: Bool = false) -> some View {
            let session = SessionStore(loginClient: LoginClientApi.client)
            session.isLoggedIn = loggedIn
            let accounts = AccountStore()
            let user = UserStore(userClient: UserClientApi.client)
            let visitors = VisitorStore(visitorClient: VisitorClientApi.client)
            let parkings = ParkingStore(parkingClient: ParkingClientApi.client)
            let parkingMeter = ParkingMeterStore(geoClient: GeoClientApi.client)
            let payment = PaymentStore(paymentClient: PaymentClientApi.client)
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
