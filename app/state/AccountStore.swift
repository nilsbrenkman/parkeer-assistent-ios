//
//  AccountStore.swift
//  parkeerassistent
//

import Foundation
import LocalAuthentication

@MainActor
class AccountStore: ObservableObject {

    @Published var accounts: [Credentials] = []
    @Published var activeAccount: Credentials?

    private var authenticated: Date?

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
            MessageStore.shared.addMessage(Lang.Account.saveFailed.localized(), type: .ERROR)
        }
        accounts = Keychain.retrieveCredentials()
    }

    func updateAccount(_ account: Credentials, username: String, password: String, alias: String?) {
        let isRecent = Keychain.getRecent(accounts)?.username == account.username
        do {
            try Keychain.updateCredentials(account, username: username, password: password, alias: alias)
        } catch {
            Log.error("updateAccount Keychain update failed: \(error.localizedDescription)")
            MessageStore.shared.addMessage(Lang.Account.saveFailed.localized(), type: .ERROR)
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
            MessageStore.shared.addMessage(Lang.Account.deleteFailed.localized(), type: .ERROR)
        }
        accounts = Keychain.retrieveCredentials()
        if isRecent {
            Keychain.setRecent(accounts.first?.username)
        }
    }

}
