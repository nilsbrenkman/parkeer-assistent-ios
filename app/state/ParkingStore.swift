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
        
    let parkingClient: ParkingClient
    
    init() {
        do {
            parkingClient = try ClientManager.instance.get(ParkingClient.self)
        } catch {
            fatalError("Failed to initialize ParkingStore: \(error)")
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
        self.parking = ParkingResponse(
            active: Array(self.parking!.active.filter({ p in
                p.id != parking.id
            })),
            scheduled: Array(self.parking!.scheduled.filter({ p in
                p.id != parking.id
            }))
        )
        
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
