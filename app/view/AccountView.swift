//
//  AccountView.swift
//  app
//
//  Created by Nils Brenkman on 10/02/2022.
//

import LocalAuthentication
import SwiftUI

@MainActor
struct AccountView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var user: UserStore
    @EnvironmentObject var router: Router
    @EnvironmentObject var accounts: AccountStore
    
    @State private var autoLogin: Bool = false
    @State private var newAccount: Bool = false
    
    var body: some View {
        Form {
            Section {
                List {
                    ForEach(accounts.accounts) { _account in
                        NavigationLink(_account.alias ?? _account.username, value: Screen.account(_account))
                            .padding(.vertical, Constants.padding.mini)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    accounts.deleteAccount(_account)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                    }
                }
            }
            Section {
                Button(
                    action: {
                        router
                            .pushScreen(
                                Screen.account(Credentials(username: "", password: ""))
                            )
                    }) {
                        Text(Lang.Common.add.localized())
                            .font(.title3)
                            .bold()
                            .centered()
                    }
                    .style(.success, disabled: false)
            }
            
        }
        .background(Color.system.groupedBackground.ignoresSafeArea())
        .onAppear(perform: load)
        .pageTitle(Lang.Account.header.localized(), dismiss: router.popScreen)
        
    }
    
    private func load() {
        Task {
            do {
                try await accounts.loadAccounts()
            } catch AuthenticationError.Unavailable {
                MessageStore.shared.addMessage(Lang.Account.errorUnavailable.localized(), type: Type.ERROR)
                presentationMode.wrappedValue.dismiss()
                return
            } catch AuthenticationError.Failed {
                MessageStore.shared.addMessage(Lang.Account.errorFailed.localized(), type: Type.WARN)
                presentationMode.wrappedValue.dismiss()
                return
            } catch {
                Log.error("loadAccounts failed: \(error.localizedDescription)")
                presentationMode.wrappedValue.dismiss()
                return
            }
            autoLogin = Keychain.autoLogin()
        }
    }
}


