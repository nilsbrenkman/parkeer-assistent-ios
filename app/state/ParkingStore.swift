//
//  User.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 22/06/2021.
//

import Foundation
import SwiftUI

@MainActor
class ParkingStore: ObservableObject {
    
    @Published var parking: ParkingResponse?
    @Published var history: [History]?

    let parkingClient: ParkingClient

    init(parkingClient: ParkingClient) {
        self.parkingClient = parkingClient
    }

    func getHistory() async {
        do {
            let response = try await parkingClient.history()
            history = response.history
        } catch {
            Log.error("getHistory failed: \(error.localizedDescription)")
        }
    }
    
    func getParking() async {
        let response: ParkingResponse
        do {
            response = try await parkingClient.get()
        } catch {
            Log.error("getParking failed: \(error.localizedDescription)")
            return
        }
        
        Notifications.store.parking(response)
        
        if response == parking {
            return
        }
        parking = ParkingResponse(active: Array(response.active),
                                  scheduled: Array(response.scheduled))
    }
        
    func startParking(_ visitor: Visitor, timeMinutes: Int, start: Date, user: UserStore, onSuccess: (() -> Void)? = nil) async {
        let response: Response
        do {
            response = try await parkingClient.start(visitor: visitor,
                                                     timeMinutes: timeMinutes,
                                                     start: start,
                                                     productId: user.productId ?? 0,
                                                     zoneId: user.zoneId ?? 0,
                                                     parkingMeterId: user.parkingMeterId ?? 0)
        } catch {
            Log.error("startParking failed: \(error.localizedDescription)")
            return
        }
        
        if response.success {
            onSuccess?()
            Stats.user.parkingCount += 1
            parking = nil
            
            await getParking()
            await user.getBalance()
            await user.getRegime(Date.now())
        } else {
            MessageStore.shared.addMessage(response.message, type: Type.ERROR)
        }
    }
    
    func stopParking(_ parking: Parking, user: UserStore) async {
        if let current = self.parking {
            self.parking = ParkingResponse(
                active: current.active.filter { $0.id != parking.id },
                scheduled: current.scheduled.filter { $0.id != parking.id }
            )
        }

        let response: Response
        do {
            response = try await parkingClient.stop(parking)
        } catch {
            Log.error("stopParking failed: \(error.localizedDescription)")
            return
        }
        
        if !response.success {
            MessageStore.shared.addMessage(response.message, type: Type.ERROR)
        }
        
        await getParking()
        await user.getBalance()
    }
    
}
