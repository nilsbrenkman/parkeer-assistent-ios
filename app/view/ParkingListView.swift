//
//  ParkingListView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 29/06/2021.
//

import SwiftUI

@MainActor
struct ParkingListView: View {

    @EnvironmentObject var user: UserStore
    @EnvironmentObject var parkings: ParkingStore

    var title: String
    var parkingList: [Parking]

    var body: some View {

        Section(header: SectionHeader(title)) {
            ForEach(parkingList, id: \.self) { parking in
                NavigationLink(value: Screen.parkingDetail(parking)) {
                    ParkingRowView(parking: parking)
                }
                .accessibility(identifier: "parking")
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await parkings.stopParking(parking, user: user)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibility(identifier: "delete-parking")
                }
            }
        }
    }

}

#if DEBUG
#Preview {
    ParkingListView(title: "Actief", parkingList: [])
        .setupPreview()
}
#endif
