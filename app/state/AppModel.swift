//
//  UserAuth.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 13/06/2021.
//

import Foundation
import LocalAuthentication
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
}

@MainActor
class AppModel: ObservableObject, ErrorHandler {
    
    @Published var isLoading: Bool = true
    @Published var isBackground: Bool = false
    @Published var isLoggedIn: Bool = false
    @Published var accounts: [Credentials] = []
    @Published var activeAccount: Credentials?
    
    @Published var path: [Screen] = []
    
    func pushScreen(_ screen: Screen) {
        path.append(screen)
    }
    
    func popScreen() {
        _ = path.popLast()
    }
    
    public var autoLogin: Bool = true
    
    private var authenticated: Date?
    
    let loginClient: LoginClient
    
    weak var user: UserModel?
    
    init() throws {
        loginClient = try ClientManager.instance.get(LoginClient.self)
        ApiClient.client.registerErrorHandler(self)
    }
    
    nonisolated func handleError(_ error: ClientError) {
        Task {
            await MainActor.run {
                switch error {
                case .Unauthorized:
                    if self.isLoggedIn {
                        MessageManager.instance.addMessage(Lang.Error.unauthorized.localized(), type: Type.WARN)
                    }
                    
                    self.clearUser()
                case .NoHttpResponse:
                    MessageManager.instance.addMessage(Lang.Error.serverUnknown.localized(), type: Type.ERROR)
                case .ServerError(let message):
                    MessageManager.instance.addMessage(message, type: Type.ERROR)
                default:
                    MessageManager.instance.addMessage(Lang.Error.serverUnknown.localized(), type: Type.ERROR)
                }
            }
        }
    }
    
    private func clearUser() {
        isLoggedIn = false
        isLoading = false
        isBackground = false
        autoLogin = false
        
        user?.isLoaded = false
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
                    MessageManager.instance.addMessage(Lang.Login.failed.localized(), type: .WARN)
                case .ServerError(let message):
                    MessageManager.instance.addMessage(message, type: .ERROR)
                default:
                    MessageManager.instance.addMessage(Lang.Login.error.localized(), type: .ERROR)
                }
                return
            }
            MessageManager.instance.addMessage(Lang.Login.error.localized(), type: .ERROR)
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
            MessageManager.instance.addMessage(response.message, type: Type.ERROR)
        }
        
    }
    
    func logout() async {
        isLoading = true
        
        do {
            let response = try await loginClient.logout()
            if !response.success {
                MessageManager.instance.addMessage(response.message, type: Type.ERROR)
            }
        } catch {
            Log.error("logout failed: \(error.localizedDescription)")
        }
        
        clearUser()
    }
    
    func selectedAccount() -> Credentials {
        Keychain.getRecent(accounts) ?? Credentials(username: "", password: "")
    }
    
    func setSelectedAccount(_ account: Credentials?) {
        Keychain.setRecent(account?.username ?? "")
    }
    
    func loadAccounts() async throws {
        let context = LAContext()
        var error: NSError?
        
        if let authenticated, authenticated.addingTimeInterval(5 * 60) > Date.now() {
            return
        }
        
        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            throw AuthenticationError.Unavailable
        }
        
        let stored = Keychain.retrieveCredentials()
        if stored.isEmpty {
            accounts = []
            return
        }
        
        let reason = Lang.Login.reason.localized()
        let success = await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { authentication, _ in
                continuation.resume(returning: authentication)
            }
        }
        
        guard success else {
            throw AuthenticationError.Failed
        }
        
        accounts = stored
        activeAccount = Keychain.getRecent(accounts) ?? accounts.first
        authenticated = Date.now()
    }
    
    func addAccount(username: String, password: String, alias: String?) {
        do {
            try Keychain.storeCredentials(username: username, password: password, alias: alias)
        } catch {
            Log.error("addAccount Keychain store failed: \(error.localizedDescription)")
        }
        accounts = Keychain.retrieveCredentials()
    }
    
    func updateAccount(_ account: Credentials, username: String, password: String, alias: String?) {
        let isRecent = Keychain.getRecent(accounts)?.username == account.username
        do {
            try Keychain.updateCredentials(account, username: username, password: password, alias: alias)
        } catch {
            Log.error("updateAccount Keychain update failed: \(error.localizedDescription)")
        }
        accounts = Keychain.retrieveCredentials()
        if isRecent {
            Keychain.setRecent(username)
        }
    }
    
    func deleteAccount(_ account: Credentials) {
        let isRecent = Keychain.getRecent(accounts)?.username == account.username
        do {
            try Keychain.deleteCredentials(account: account)
        } catch {
            Log.error("deleteAccount Keychain delete failed: \(error.localizedDescription)")
        }
        accounts = Keychain.retrieveCredentials()
        if isRecent {
            Keychain.setRecent(accounts.first?.username)
        }
    }
    
}
