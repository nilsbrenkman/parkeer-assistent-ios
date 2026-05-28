//
//  User.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 22/06/2021.
//

import Foundation
import MapKit
import SwiftUI

@MainActor
class UserModel: ObservableObject {
    
    @Published var balance: String?
    @Published var hourRate: Double?
    @Published var timeBalance: Int = 0
    @Published var regimeTimeStart: Date?
    @Published var regimeTimeEnd: Date?
    @Published var regime: Regime?
    @Published var productId: Int?
    @Published var zoneId: Int?
    @Published var parkingMeterId: Int?
    @Published var visitors: [Visitor]?
    @Published var parking: ParkingResponse?
    
    @Published var isLoaded: Bool = false
    @Published var isPaymentInProgress: Bool = false
    
    @Published var position: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: .amsterdam,
        distance: 1000,
        heading: 0,
        pitch: 0
    ))
    @Published var parkingMeters: [ParkingMeter] = []
    @Published var lastLocation: CLLocationCoordinate2D? = nil
    
    let loginClient: LoginClient
    let userClient: UserClient
    let parkingClient: ParkingClient
    let visitorClient: VisitorClient
    let paymentClient: PaymentClient
    
    init() throws {
        loginClient = try ClientManager.instance.get(LoginClient.self)
        userClient = try ClientManager.instance.get(UserClient.self)
        parkingClient = try ClientManager.instance.get(ParkingClient.self)
        visitorClient = try ClientManager.instance.get(VisitorClient.self)
        paymentClient = try ClientManager.instance.get(PaymentClient.self)
    }
    
    func getUser() async {
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
        setRegimeForDate(Date.now)
        timeBalance = Util.calculateTimeBalance(balance: response.balance,
                                                hourRate: 0.01)
        await getVisitors()
        await getParking()
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
            
            MessageManager.instance.addMessage(Lang.Parking.freeParking.localized(), type: Type.WARN)
            
            return
        }
        regimeTimeStart = getRegimeTime(date: date, time: regimeDay.startTime)
        regimeTimeEnd = getRegimeTime(date: date, time: regimeDay.endTime)
    }
    
    func getRegimeTime(date: Date, time: String) -> Date? {
        let times = time.split(separator: ":")
        return Calendar.current.date(bySettingHour: Int(times[0]) ?? 0, minute: Int(times[1]) ?? 0, second: 0, of: date)
    }
    
    func getVisitors() async {
        let response: VisitorResponse
        do {
            response = try await visitorClient.get()
        } catch {
            Log.error("getVisitors failed: \(error.localizedDescription)")
            return
        }
        
        let sorted = response.visitors.sorted()
        if sorted == visitors {
            return
        }
        visitors = sorted
    }
    
    func addVisitor(license: String, name: String, onSuccess: (() -> Void)? = nil) async {
        let response: Response
        do {
            response = try await visitorClient.add(license: license, name: name)
        } catch {
            Log.error("addVisitor failed: \(error.localizedDescription)")
            return
        }
        
        if response.success {
            onSuccess?()
            Stats.user.visitorCount += 1
            visitors = nil
            await getVisitors()
        } else {
            MessageManager.instance.addMessage(response.message, type: Type.ERROR)
        }
    }
    
    func deleteVisitor(_ visitor: Visitor) async {
        let response: Response
        do {
            response = try await visitorClient.delete(visitor)
        } catch {
            Log.error("deleteVisitor failed: \(error.localizedDescription)")
            return
        }
        
        if !response.success {
            MessageManager.instance.addMessage(response.message, type: Type.ERROR)
        }
        await getVisitors()
    }
    
    func getParking() async {
        let response: ParkingResponse
        do {
            response = try await parkingClient.get()
        } catch {
            Log.error("getParking failed: \(error.localizedDescription)")
            return
        }
        
        Notifications.store.parking(response, visitors: visitors)
        
        if response == parking {
            return
        }
        parking = ParkingResponse(active: Array(response.active),
                                  scheduled: Array(response.scheduled))
    }
    
    func setParkingMeter(_ parkingMeterId: Int) {
        self.parkingMeterId = parkingMeterId
        
        Task {
            let response: RegimeResponse
            do {
                response = try await userClient.regime(parkingMeterId: parkingMeterId)
            } catch {
                Log.error("setParkingMeter regime fetch failed: \(error.localizedDescription)")
                MessageManager.instance.addMessage("Invalid zone", type: Type.ERROR)
                return
            }
            self.hourRate = response.hourRate
            self.zoneId = response.zoneId
            self.regime = response.regime
        }
    }
    
    func startParking(_ visitor: Visitor, timeMinutes: Int, start: Date, onSuccess: (() -> Void)? = nil) async {
        let response: Response
        do {
            response = try await parkingClient.start(visitor: visitor,
                                                     timeMinutes: timeMinutes,
                                                     start: start,
                                                     productId: productId ?? 0,
                                                     zoneId: zoneId ?? 0,
                                                     parkingMeterId: parkingMeterId ?? 0)
        } catch {
            Log.error("startParking failed: \(error.localizedDescription)")
            return
        }
        
        if response.success {
            onSuccess?()
            Stats.user.parkingCount += 1
            parking = nil
            
            await getParking()
            await getBalance()
            await getRegime(Date.now())
        } else {
            MessageManager.instance.addMessage(response.message, type: Type.ERROR)
        }
    }
    
    func stopParking(_ parking: Parking) async {
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
            MessageManager.instance.addMessage(response.message, type: Type.ERROR)
        }
        
        await getParking()
        await getBalance()
    }
    
    func getName(from licence: String) -> String {
        if let visitorList = visitors {
            for visitor in visitorList {
                if visitor.license.lowercased() == licence.lowercased() {
                    return visitor.name ?? ""
                }
            }
        }
        return ""
    }
    
    func payment(amount: Int, brand: String, onSuccess: ((String) -> Void)) async {
        let response: PaymentResponse
        do {
            response = try await paymentClient.payment(amount: amount, brand: brand)
        } catch {
            Log.error("payment failed: \(error.localizedDescription)")
            return
        }
        self.isPaymentInProgress = true
        onSuccess(response.url)
    }
    
}

enum Page {
    case history, payment, account, settings, visitor, parking
}
