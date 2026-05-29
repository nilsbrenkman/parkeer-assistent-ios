//
//  UserAuth.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 13/06/2021.
//

import Foundation
import SwiftUI

@MainActor
class SessionStore: ObservableObject, ErrorHandler {
    
    @Published var isLoading: Bool = true
    @Published var isBackground: Bool = false
    @Published var isLoggedIn: Bool = false
    
    public var autoLogin: Bool = true
    
    let loginClient: LoginClient

    init(loginClient: LoginClient) {
        self.loginClient = loginClient
        ApiClient.client.registerErrorHandler(self)
    }
    
    nonisolated func handleError(_ error: ClientError) {
        Task { @MainActor in
            switch error {
            case .Unauthorized:
                if self.isLoggedIn {
                    MessageStore.shared.addMessage(Lang.Error.unauthorized.localized(), type: Type.WARN)
                }
                self.clearUser()
            case .NoHttpResponse:
                MessageStore.shared.addMessage(Lang.Error.serverUnknown.localized(), type: Type.ERROR)
            case .ServerError(let message):
                MessageStore.shared.addMessage(message, type: Type.ERROR)
            default:
                MessageStore.shared.addMessage(Lang.Error.serverUnknown.localized(), type: Type.ERROR)
            }
        }
    }
    
    private func clearUser() {
        isLoggedIn = false
        isLoading = false
        isBackground = false
        autoLogin = false
    }
    
    func loggedIn() async {
        isLoading = true
        
        let response: Response
        do {
            response = try await loginClient.loggedId()
        } catch {
            Log.error("loggedIn check failed: \(error.localizedDescription)")
            isLoggedIn = false
            isLoading = false
            return
        }
        
        isLoggedIn = response.success
        isLoading = false
    }
    
    func login(username: String, password: String, storeCredentials: Bool) async {
        
        let response: Response
        do {
            response = try await loginClient.login(username: username, password: password)
        } catch {
            if let clientError = error as? ClientError {
                switch clientError {
                case .Unauthorized:
                    MessageStore.shared.addMessage(Lang.Login.failed.localized(), type: .WARN)
                case .ServerError(let message):
                    MessageStore.shared.addMessage(message, type: .ERROR)
                default:
                    MessageStore.shared.addMessage(Lang.Login.error.localized(), type: .ERROR)
                }
                return
            }
            MessageStore.shared.addMessage(Lang.Login.error.localized(), type: .ERROR)
            return
        }
        
        if response.success {
            Stats.user.loginCount += 1
            if storeCredentials {
                do {
                    try Keychain.storeCredentials(username: username, password: password, alias: nil)
                    Keychain.setRecent(username)
                } catch {
                    Log.warning("Store credentials failed: \(error)")
                }
            }
            isLoggedIn = true
            
        } else {
            MessageStore.shared.addMessage(response.message, type: Type.ERROR)
        }
        
    }
    
    func logout() async {
        do {
            let response = try await loginClient.logout()
            if !response.success {
                MessageStore.shared.addMessage(response.message, type: Type.ERROR)
            }
        } catch {
            Log.error("logout failed: \(error.localizedDescription)")
        }
        
        clearUser()
    }
    
}
