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
            let app = AppModel()
            app.isLoggedIn = loggedIn
            let user = UserModel()
            let messenger = AppMessenger()
            return environmentObject(app)
                .environmentObject(user)
                .environmentObject(messenger)
        }

    }
#endif
