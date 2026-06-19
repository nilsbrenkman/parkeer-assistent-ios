//
//  HistoryListView.swift
//  app
//
//  Created by Nils Brenkman on 16/11/2021.
//

import SwiftUI

@MainActor
struct HistoryView: View {
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var visitors: VisitorStore

    var history: History

    var body: some View {
        Form {
            Section {
                List {
                    LicenseView(license: history.license)
                        .centered()
                        .padding(.vertical, Constants.padding.small)

                    Property(label: Lang.Visitor.name.localized(), text: visitors.getName(from: history.license))
                    Property(label: Lang.Parking.cost.localized(), text: "€ \(Util.formatCost(history.cost))")
                    Property(label: Lang.Parking.startTime.localized(), text: Util.formatDateTime(history.startTime))
                    Property(label: Lang.Parking.endTime.localized(), text: Util.formatDateTime(history.endTime))
                }
            }
        }
        .pageTitle(Lang.Parking.details.localized(), dismiss: router.popScreen)
    }
}

#if DEBUG
#Preview {
    HistoryView(history: History(id: 0, license: "", startTime: "", endTime: "", cost: 0))
        .setupPreview()
}
#endif
