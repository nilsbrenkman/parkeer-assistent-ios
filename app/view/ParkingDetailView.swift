//
//  ParkingDetailView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 03/07/2021.
//

import SwiftUI

@MainActor
struct ParkingDetailView: View {

    @EnvironmentObject var app: AppModel
    @EnvironmentObject var user: UserModel

    var parking: Parking

    var body: some View {
        Form {

            Section {
                VStack(alignment: .leading, spacing: Constants.spacing.normal) {
                    LicenseView(license: parking.license)
                        .centered()

                    Property(label: Lang.Visitor.name.localized(), text: user.getName(from: parking.license))
                    Property(label: Lang.Parking.cost.localized(), text: "€ \(Util.formatCost(parking.cost))")
                    Property(label: Lang.Parking.startTime.localized(), text: Util.getParkingTime(parking.startTime))
                    Property(label: Lang.Parking.endTime.localized(), text: Util.getParkingTime(parking.endTime))
                }
                .padding(.vertical)
            }

            Section {
                Button(action: {
                    Task {
                        await user.stopParking(parking)
                    }
                    app.popScreen()
                }) {
                    Text(Lang.Parking.stop.localized())
                        .font(.title3)
                        .bold()
                        .centered()
                }
                .style(.danger)
            }
        }
        .pageTitle(Lang.Parking.header.localized(), dismiss: app.popScreen)
    }
}

#Preview {
    ParkingDetailView(parking: Parking(id: 0, license: "12-AB-CD", startTime: "", endTime: "", cost: 12.34))
        .setupPreview()
}
