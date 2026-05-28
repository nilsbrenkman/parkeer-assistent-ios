//
//  ContentView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 12/06/2021.
//

import SwiftUI
import WatchConnectivity

@MainActor
struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var user: UserModel
    @EnvironmentObject var messenger: AppMessenger
    
    @State var initialised = false
    @State var showInfo = false
    @State var showHistory = false
    @State var showAccounts = false
    @State var showSettings = false
    
    @State var showLogin: Bool = false
    @State var showUser: Bool = false
    
    let semaphore = DispatchSemaphore(value: 2)
    
    var body: some View {
        
        NavigationStack(path: $app.path) {
            
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
        .message(message: $messenger.message)
        .onAppear {
            if !initialised {
                semaphore.wait()
                print("take")
                Task {
                    await app.loggedIn()
                    initialised = true
                    app.user = user
                }
                Task {
                    try await Task.sleep(nanoseconds: 1_000_000)
                    print("release")
                    semaphore.signal()
                }
            }
        }
        .onChange(of: scenePhase) { phase, initial in
            if phase == .background {
                app.isBackground = true
            } else if app.isBackground {
                app.isBackground = false
                Task {
                    await app.loggedIn()
                }
            }
        }
        .onChange(of: app.isLoggedIn) { onChangeRoot() }
        .onChange(of: app.isLoading) { onChangeRoot() }
        .onChange(of: app.isBackground) { onChangeRoot() }
    }
    
    private func onChangeRoot() {
        if app.isLoading || app.isBackground {
            app.path = []
        } else {
            if app.isLoggedIn {
                app.path = [Screen.user]
            } else {
                app.path = [Screen.login]
            }
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
