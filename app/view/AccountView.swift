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
    
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var user: UserModel
    
    @State private var autoLogin: Bool = false
    @State private var newAccount: Bool = false
    
    var body: some View {
        Form {
            Section {
                List {
                    ForEach(app.accounts) { _account in
                        NavigationLink(_account.alias ?? _account.username, value: Screen.account(_account))
                            .padding(.vertical, Constants.padding.mini)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    app.deleteAccount(_account)
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
                        app
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
        .pageTitle(Lang.Account.header.localized(), dismiss: app.popScreen)
        
    }
    
    private func load() {
        Task {
            do {
                try await app.loadAccounts()
            } catch AuthenticationError.Unavailable {
                MessageManager.instance.addMessage(Lang.Account.errorUnavailable.localized(), type: Type.ERROR)
                presentationMode.wrappedValue.dismiss()
                return
            } catch AuthenticationError.Failed {
                MessageManager.instance.addMessage(Lang.Account.errorFailed.localized(), type: Type.WARN)
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


