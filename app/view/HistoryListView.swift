//
//  HistoryView.swift
//  app
//
//  Created by Nils Brenkman on 16/11/2021.
//

import SwiftUI

@MainActor
struct HistoryListView: View {

    static let groupFormatter = Util.createDateFormatter("MMMM yyyy")

    @EnvironmentObject var user: UserStore
    @EnvironmentObject var router: Router
    @EnvironmentObject var parkings: ParkingStore

    var body: some View {
        List {
            if let history = parkings.history {
                if history.isEmpty {
                    Section {
                        Text(Lang.Parking.noHistory.localized())
                            .centered()
                    } header: {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 1)
                    }
                } else {
                    let groupedHistory = groupHistory(history)
                    ForEach(groupedHistory, id: \.date) { group in
                        Section(
                            header: SectionHeader(
                                HistoryListView.groupFormatter.string(from: group.date)
                            )
                        ) {
                            ForEach(group.history, id: \.self) { h in
                                NavigationLink(destination: HistoryView(history: h)) {
                                    HistoryRowView(history: h)
                                }
                            }
                        }
                    }
                }
            } else {
                Section {
                    ProgressView()
                        .centered()
                } header: {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .task {
            await parkings.getHistory()
        }
        .pageTitle(Lang.Parking.history.localized(), dismiss: router.popScreen)
    }

    private func groupHistory(_ history: [History]) -> [HistoryGroup] {
        var list: [HistoryGroup] = []
        var group: HistoryGroup?
        for h in history {
            group = addToGroup(h, group: group, list: &list)
        }
        if group != nil {
            list.append(group!)
        }
        return list
    }

    private func addToGroup(_ history: History, group: HistoryGroup?, list: inout [HistoryGroup])
        -> HistoryGroup
    {
        guard var group = group else {
            return HistoryGroup(date: history.date, history: [history])
        }
        if Calendar.current.isDate(history.date, equalTo: group.date, toGranularity: .month) {
            group.history.append(history)
            return group
        }
        list.append(group)
        return HistoryGroup(date: history.date, history: [history])
    }

}

struct HistoryGroup {
    var date: Date
    var history: [History]
}

#Preview {
    HistoryListView()
        .setupPreview()
}
