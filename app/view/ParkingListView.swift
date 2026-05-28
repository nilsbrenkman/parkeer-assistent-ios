//
//  ParkingListView.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 29/06/2021.
//

import SwiftUI

@MainActor
struct ParkingListView: View {

    @EnvironmentObject var user: UserModel

    var title: String
    var parkingList: [Parking]

    var body: some View {

        Section(header: SectionHeader(title)) {
            ForEach(parkingList, id: \.self) { parking in
                NavigationLink(destination: ParkingDetailView(parking: parking)) {
                    ParkingRowView(parking: parking)
                }
                .accessibility(identifier: "parking")
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await user.stopParking(parking)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }

}

struct ParkingListView_Previews: PreviewProvider {
    static var previews: some View {
        ParkingListView(title: "Actief", parkingList: [])
    }
}
