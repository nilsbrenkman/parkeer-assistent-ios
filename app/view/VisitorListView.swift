//
//  VisitorListView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 22/06/2021.
//

import Foundation
import SwiftUI

struct VisitorListView: View {

    @EnvironmentObject var router: Router
    @EnvironmentObject var visitors: VisitorStore

    var body: some View {

        Section(header: SectionHeader(Lang.Visitor.header.localized())) {

            if let list = visitors.visitors {

                if list.isEmpty {
                    Text(Lang.Visitor.noVisitors.localized())
                        .centered()
                } else {
                    ForEach(list, id: \.self) { visitor in
                        Button(action: {
                            router.pushScreen(.addParking(visitor))
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
                if let list = visitors.visitors, list.count >= 9 {
                    MessageStore.shared.addMessage(Lang.Visitor.tooManyMsg.localized(), type: Type.WARN)
                    return
                }
                router.pushScreen(.addVisitor)
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
        guard let index = visitors.visitors?.firstIndex(of: visitor) else { return }
        visitors.visitors!.remove(at: index)
        Task {
            await visitors.deleteVisitor(visitor)
        }
    }

}

#Preview {
    VisitorListView()
        .setupPreview()
}
