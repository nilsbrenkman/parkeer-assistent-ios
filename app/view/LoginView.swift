//
//  LoginView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 12/06/2021.
//

import LocalAuthentication
import SwiftUI

struct LoginView: View {

    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var accounts: AccountStore

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var storeCredentials: Bool = false
    @State private var isBackground: Bool = false
    @State private var wait: Bool = false
    @State private var canAuthenticate = true
    @State private var authenticationFailed = false
    @State private var selectedAccount: Credentials?

    var body: some View {
        Form {
            Section(header: SectionHeader(Lang.Login.login.localized())
                                .padding(.top, Constants.padding.normal)) {
                HStack {
                    Text(Lang.Login.username.localized())
                        .frame(alignment: .leading)
                    TextField("", text: $username)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, Constants.padding.mini)
                HStack {
                    Text(Lang.Login.password.localized())
                        .frame(alignment: .leading)
                    SecureField("", text: $password)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, Constants.padding.mini)
            }
            Section {
                Button(action: startLogin) {
                    Text(Lang.Login.login.localized())
                        .font(.title3)
                        .bold()
                        .wait($wait)
                }
                .style(.success, disabled: username.count == 0 || password.count == 0)
            }
            if accounts.accounts.isEmpty {
                if authenticationFailed {
                    Section {
                        HStack {
                            Spacer()
                            Image(systemName: "faceid")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    session.autoLogin = true
                                    authenticate()
                                }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.system.groupedBackground)
                } else if canAuthenticate {
                    Section {
                        Toggle(Lang.Login.remember.localized(), isOn: $storeCredentials)
                    }
                }
            } else {
                Section {
                    Picker(Lang.Account.label.localized(), selection: $accounts.activeAccount) {
                        ForEach(accounts.accounts) { _account in
                            Text(_account.alias ?? _account.username).tag(_account)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear(perform: authenticate)
        .onChange(of: scenePhase) { phase, initial in
            if phase == .background {
                isBackground = true
            } else if isBackground {
                isBackground = false
                if username.isEmpty && password.isEmpty {
                    authenticate()
                }
            }
        }
        .onChange(of: accounts.activeAccount) {
            if let selectedAccount = accounts.activeAccount {
                changeAccount(selectedAccount)
            }
        }
    }

    private func startLogin() {
        if !wait {
            Task {
                wait = true
                await session.login(username: username,
                                    password: password,
                                    storeCredentials: storeCredentials)
                wait = false
            }
        }
    }

    private func authenticate() {
        Task {
            do {
                try await accounts.loadAccounts()
            } catch AuthenticationError.Unavailable {
                canAuthenticate = false
                username = ""
                password = ""
                return
            } catch AuthenticationError.Failed {
                authenticationFailed = true
                username = ""
                password = ""
                return
            } catch {
                Log.error("loadAccounts failed: \(error.localizedDescription)")
                username = ""
                password = ""
                return
            }

            if let account = accounts.activeAccount, username.isEmpty {
                username = account.username
                password = account.password
            }

            if session.autoLogin && Keychain.autoLogin() {
                session.autoLogin = false
                startLogin()
            }
        }
    }

    private func changeAccount(_ account: Credentials) {
        Keychain.setRecent(account.username)
        username = account.username
        password = account.password
    }

}

#if DEBUG
#Preview {
    LoginView()
        .setupPreview()
}
#endif
