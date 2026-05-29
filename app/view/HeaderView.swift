//
//  HeaderView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 30/06/2021.
//

import SwiftUI

struct HeaderView: View {
    
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var user: UserStore
    @EnvironmentObject var router: Router
    
    let loggedIn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            ZStack {
                Rectangle()
                    .fill(Color.ui.header)
                    .frame(height: 68)
                HStack {
                    if !loggedIn {
                        Spacer()
                    }
                    Image("Image-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 48)
                        .animation(.linear, value: 0)
                        .onTapGesture {
                            router.pushScreen(.info)
                        }
                    Spacer()
                    if loggedIn {
                        Menu {
                            Button(action: { router.pushScreen(.history) }) {
                                Text(Lang.Parking.history.localized())
                                Image(systemName: "clock")
                            }
                            Button(action: { router.pushScreen(.payment) }) {
                                Text(Lang.User.addBalance.localized())
                                Image(systemName: "eurosign.circle")
                            }
                            Button(action: { router.pushScreen(.accounts) }) {
                                Text(Lang.Account.header.localized())
                                Image(systemName: "person")
                            }
                            Button(action: { router.pushScreen(.settings) }) {
                                Text(Lang.Settings.header.localized())
                                Image(systemName: "gearshape")
                            }
                            Button(action: logout) {
                                Text(Lang.Login.logout.localized())
                                Image(systemName: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 38)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 8)
                                .foregroundColor(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: Constants.radius.small)
                                    .stroke(Color.white, lineWidth: 1)
                                )
                                .accessibilityIdentifier("menu")
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if loggedIn {
                
                HStack {
                    Spacer()
                    Text("\(Lang.User.balance.localized()):")
                        .foregroundColor(Color.ui.header)
                        .padding(.vertical, 8)
                    Text("€ \(user.balance ?? "--")")
                        .bold()
                        .foregroundColor(Color.ui.header)
                        .padding(.vertical, 8)
                        .accessibilityIdentifier("balance")
                    
                }
                .padding(.horizontal)
                .background(Color.ui.light)
                .onTapGesture {
                    Task {
                        await user.getBalance()
                    }
                }

                Rectangle()
                    .frame(height: 1)
                    .border(Color.ui.header, width: 1)

            }
            
        }
        .background(Color.ui.header)
    }
    
    private func logout() {
        Task {
            await session.logout()
        }
    }
    
}

#Preview {
    HeaderView(loggedIn: true)
        .setupPreview()
}
