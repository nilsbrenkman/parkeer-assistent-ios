//
//  VisitorListView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 22/06/2021.
//

import Foundation
import SwiftUI

struct VisitorListView: View {

    @EnvironmentObject var app: AppModel
    @EnvironmentObject var user: UserModel

    var body: some View {

        Section(header: SectionHeader(Lang.Visitor.header.localized())) {

            if let visitors = $user.visitors.wrappedValue {

                if visitors.isEmpty {
                    Text(Lang.Visitor.noVisitors.localized())
                        .centered()
                } else {
                    ForEach(visitors, id: \.self) { visitor in
                        Button(action: {
                            app.pushScreen(.addParking(visitor))
                        }) {
                            HStack {
                                VisitorView(visitor: visitor)
                                Spacer()
                            }
                        }
                        .accessibility(identifier: "visitor")
                        .foregroundColor(.primary)
                        .frame(minHeight: 42)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(visitor)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            } else {
                ProgressView()
                    .centered()
            }
        }

        Section {
            Button(action: {
                if let visitors = $user.visitors.wrappedValue {
                    if visitors.count >= 9 {
                        MessageManager.instance.addMessage(Lang.Visitor.tooManyMsg.localized(), type: Type.WARN)
                        return
                    }
                }
                app.pushScreen(.addVisitor)
            }) {
                Text(Lang.Visitor.add.localized())
                    .font(.title3)
                    .bold()
                    .centered()
            }
            .style(.success)
        }
    }

    func delete(_ visitor: Visitor) {
        guard let index = user.visitors?.firstIndex(of: visitor) else { return }
        user.visitors!.remove(at: index)
        Task {
            await user.deleteVisitor(visitor)
        }
    }

}

struct VisitorListView_Previews: PreviewProvider {
    static var previews: some View {
        VisitorListView()
    }
}
