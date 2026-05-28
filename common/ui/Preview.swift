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
            let login = try! AppModel()
            login.isLoggedIn = loggedIn

            let user = try! UserModel()
            
            return environmentObject(login)
                .environmentObject(user)
                
        }

    }
#endif
