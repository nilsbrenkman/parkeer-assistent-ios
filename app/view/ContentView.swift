//
//  ContentView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 12/06/2021.
//

import SwiftUI

@MainActor
struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var user: UserStore
    @EnvironmentObject var router: Router
    @EnvironmentObject var messages: MessageStore
    
    @State var initialised = false

    var body: some View {
        
        NavigationStack(path: $router.path) {
            
            LoadingView()
                .navigationDestination(for: Screen.self) { screen in
                    switch screen {
                    case .login:
                        VStack(alignment: .leading, spacing: 0) {
                            HeaderView(loggedIn: false)
                            LoginView()
                        }
                        .navigationBarBackButtonHidden(true)
                    case .user:
                        VStack(alignment: .leading, spacing: 0) {
                            HeaderView(loggedIn: true)
                            UserView()
                        }
                    case .info:
                        InfoView()
                    case .history:
                        HistoryListView()
                    case .payment:
                        PaymentView()
                    case .accounts:
                        AccountView()
                    case .account(let account):
                        AccountDetailView(account: account)
                    case .settings:
                        SettingsView()
                    case .addVisitor:
                        AddVisitorView()
                    case .addParking(let visitor):
                        AddParkingView(visitor: visitor)
                    }
                }
        }
        .message(message: $messages.message)
        .onAppear {
            if !initialised {
                Task {
                    await session.loggedIn()
                    initialised = true
                }
            }
        }
        .onChange(of: scenePhase) { phase, initial in
            if phase == .background {
                session.isBackground = true
            } else if session.isBackground {
                session.isBackground = false
                Task {
                    await session.loggedIn()
                }
            }
        }
        .onChange(of: rootState) { _, _ in
            router.syncRoot(
                isLoggedIn: session.isLoggedIn,
                isLoading: session.isLoading,
                isBackground: session.isBackground
            )
            if !session.isLoggedIn && !session.isLoading && !session.isBackground {
                user.reset()
            }
        }
    }

    private var rootState: RootState {
        RootState(isLoggedIn: session.isLoggedIn,
                  isLoading: session.isLoading,
                  isBackground: session.isBackground)
    }

}

private struct RootState: Equatable {
    let isLoggedIn: Bool
    let isLoading: Bool
    let isBackground: Bool
}

#Preview {
    ContentView()
        .setupPreview(loggedIn: true)
}
