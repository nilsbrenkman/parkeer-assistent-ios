//
//  User.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 22/06/2021.
//

import Foundation
import SwiftUI

@MainActor
class UserStore: ObservableObject {
    
    @Published var balance: String?
    @Published var hourRate: Double?
    @Published var timeBalance: Int = 0
    @Published var regimeTimeStart: Date?
    @Published var regimeTimeEnd: Date?
    @Published var regime: Regime?
    @Published var productId: Int?
    @Published var zoneId: Int?
    @Published var parkingMeterId: Int?
    
    @Published var isLoaded: Bool = false
    
    let userClient: UserClient

    init(userClient: UserClient) {
        self.userClient = userClient
    }

    func reset() {
        balance = nil
        hourRate = nil
        timeBalance = 0
        regimeTimeStart = nil
        regimeTimeEnd = nil
        regime = nil
        productId = nil
        zoneId = nil
        parkingMeterId = nil
        isLoaded = false
    }
    
    func getUser(_ onComplete: (() async -> Void)) async {
        let response: UserResponse
        do {
            response = try await userClient.get()
        } catch {
            Log.error("getUser failed: \(error.localizedDescription)")
            return
        }
        
        balance = response.balance
        hourRate = response.hourRate
        regime = response.regime
        productId = response.productId
        zoneId = response.zoneId
        parkingMeterId = response.parkingMeterId
        setRegimeForDate(Date.now())
        timeBalance = Util.calculateTimeBalance(balance: response.balance,
                                                hourRate: 0.01)
        await onComplete()
    }
    
    func getBalance() async {
        let response: BalanceResponse
        do {
            response = try await userClient.balance()
        } catch {
            Log.error("getBalance failed: \(error.localizedDescription)")
            return
        }
        
        if response.balance == balance {
            return
        }
        balance = response.balance
        timeBalance = Util.calculateTimeBalance(balance: response.balance,
                                                hourRate: hourRate)
    }
    
    func getRegime(_ date: Date) async {
        if regime != nil {
            setRegimeForDate(date)
            return
        }
    }
    
    func setRegimeForDate(_ date: Date) {
        guard let regime,
              let regimeDay = Util.getRegimeDay(regime: regime, date: date) else {
            regimeTimeStart = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)
            regimeTimeEnd = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)
            
            MessageStore.shared.addMessage(Lang.Parking.freeParking.localized(), type: Type.WARN)
            
            return
        }
        regimeTimeStart = getRegimeTime(date: date, time: regimeDay.startTime)
        regimeTimeEnd = getRegimeTime(date: date, time: regimeDay.endTime)
    }
    
    func getRegimeTime(date: Date, time: String) -> Date? {
        let times = time.split(separator: ":")
        return Calendar.current.date(bySettingHour: Int(times[0]) ?? 0, minute: Int(times[1]) ?? 0, second: 0, of: date)
    }
    
    func setParkingMeter(_ parkingMeterId: Int) {
        self.parkingMeterId = parkingMeterId
        
        Task {
            let response: RegimeResponse
            do {
                response = try await userClient.regime(parkingMeterId: parkingMeterId)
            } catch {
                Log.error("setParkingMeter regime fetch failed: \(error.localizedDescription)")
                MessageStore.shared.addMessage(Lang.Parking.invalidZone.localized(), type: Type.ERROR)
                return
            }
            self.hourRate = response.hourRate
            self.zoneId = response.zoneId
            self.regime = response.regime
        }
    }
    
}
