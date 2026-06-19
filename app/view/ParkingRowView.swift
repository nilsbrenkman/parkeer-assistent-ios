//
//  ParkingView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 29/06/2021.
//

import SwiftUI

@MainActor
struct ParkingRowView: View {

    @EnvironmentObject var visitors: VisitorStore

    var parking: Parking

    var body: some View {

        HStack {
            LicenseView(license: parking.license)

            VStack(alignment: .leading) {
                Text("\(visitors.getName(from: parking.license))")
                    .font(.title3)
                    .bold()
                    .padding(.leading)
                Text("\(Util.formatDate(parking.startTime)), \(Util.formatTime(parking.startTime)) - \(Util.formatTime(parking.endTime))")
                    .font(.footnote)
                    .padding(.leading)
            }

        }
        .frame(minHeight: 42)
    }

}

#if DEBUG
#Preview {
    ParkingRowView(
        parking: Parking(id: 0, license: "12-AB-CD", startTime: "", endTime: "", cost: 12.34)
    )
    .setupPreview()
}
#endif
