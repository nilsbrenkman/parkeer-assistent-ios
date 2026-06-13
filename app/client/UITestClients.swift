//
//  UITestClients.swift
//  parkeerassistent
//

import CoreLocation
import Foundation

enum Clients {
    #if DEBUG
    static let login: LoginClient = Util.isUITest() ? UITestLoginClient() : LoginClientApi.client
    static let user: UserClient = Util.isUITest() ? UITestUserClient() : UserClientApi.client
    static let visitor: VisitorClient = Util.isUITest() ? UITestVisitorClient() : VisitorClientApi.client
    static let parking: ParkingClient = Util.isUITest() ? UITestParkingClient() : ParkingClientApi.client
    static let payment: PaymentClient = Util.isUITest() ? UITestPaymentClient() : PaymentClientApi.client
    static let geo: GeoClient = Util.isUITest() ? UITestGeoClient() : GeoClientApi.client
    #else
    static let login: LoginClient = LoginClientApi.client
    static let user: UserClient = UserClientApi.client
    static let visitor: VisitorClient = VisitorClientApi.client
    static let parking: ParkingClient = ParkingClientApi.client
    static let payment: PaymentClient = PaymentClientApi.client
    static let geo: GeoClient = GeoClientApi.client
    #endif
}

#if DEBUG

final class UITestBackend {

    static let shared = UITestBackend()

    let hourRate = 2.0
    let parkingMeterId = 1234

    var loggedIn = false
    var balance = "10.00"

    var visitors: [Visitor] = [
        Visitor(id: 1, license: "11AAA1", formattedLicense: "11-AAA-1", name: "Anna"),
        Visitor(id: 2, license: "22BBB2", formattedLicense: "22-BBB-2", name: "Erik"),
        Visitor(id: 3, license: "33CCC3", formattedLicense: "33-CCC-3", name: "Maria"),
        Visitor(id: 4, license: "44DDD4", formattedLicense: "44-DDD-4", name: "Sara"),
    ]
    var active: [Parking] = []
    var scheduled: [Parking] = []

    private var nextVisitorId = 5
    private var nextParkingId = 1

    private init() {
        //
    }

    var regime: Regime {
        Regime(days: Util.weekdays.map { weekday in
            RegimeDay(weekday: weekday, startTime: "00:00", endTime: "23:59")
        })
    }

    func addVisitor(license: String, name: String) {
        let visitor = Visitor(id: nextVisitorId,
                              license: String(License.normalise(license)),
                              formattedLicense: License.formatLicense(license),
                              name: name)
        nextVisitorId += 1
        visitors.append(visitor)
    }

    func deleteVisitor(_ visitor: Visitor) {
        visitors.removeAll { $0.id == visitor.id }
    }

    func startParking(visitor: Visitor, timeMinutes: Int, start: Date) {
        let end = start.addingTimeInterval(TimeInterval(timeMinutes * 60))
        let parking = Parking(id: nextParkingId,
                              license: visitor.license,
                              startTime: Util.dateTimeFormatter.string(from: start),
                              endTime: Util.dateTimeFormatter.string(from: end),
                              cost: (hourRate * Double(timeMinutes)) / 60)
        nextParkingId += 1
        // Compare against the (frozen, in UI tests) app clock so that a parking
        // whose start was nudged into the future is reliably classified as
        // scheduled rather than active.
        if start.timeIntervalSince(Date.now()) < 60 {
            active.append(parking)
        } else {
            scheduled.append(parking)
        }
    }

    func stopParking(_ parking: Parking) {
        active.removeAll { $0.id == parking.id }
        scheduled.removeAll { $0.id == parking.id }
    }

}

final class UITestLoginClient: LoginClient {

    func loggedId() async throws -> Response {
        Response(success: UITestBackend.shared.loggedIn)
    }

    func login(username: String, password: String) async throws -> Response {
        if username == "test" && password == "1234" {
            UITestBackend.shared.loggedIn = true
            return Response(success: true)
        }
        return Response(success: false, message: "Login failed")
    }

    func logout() async throws -> Response {
        UITestBackend.shared.loggedIn = false
        return Response(success: true)
    }

}

final class UITestUserClient: UserClient {

    func get() async throws -> UserResponse {
        let backend = UITestBackend.shared
        return UserResponse(balance: backend.balance,
                            hourRate: backend.hourRate,
                            productId: 1,
                            zoneId: 1,
                            parkingMeterId: backend.parkingMeterId,
                            regime: backend.regime)
    }

    func balance() async throws -> BalanceResponse {
        BalanceResponse(balance: UITestBackend.shared.balance)
    }

    func regime(parkingMeterId: Int) async throws -> RegimeResponse {
        let backend = UITestBackend.shared
        return RegimeResponse(hourRate: backend.hourRate, zoneId: 1, regime: backend.regime)
    }

}

final class UITestVisitorClient: VisitorClient {

    func get() async throws -> VisitorResponse {
        VisitorResponse(visitors: UITestBackend.shared.visitors)
    }

    func add(license: String, name: String) async throws -> Response {
        UITestBackend.shared.addVisitor(license: license, name: name)
        return Response(success: true)
    }

    func delete(_ visitor: Visitor) async throws -> Response {
        UITestBackend.shared.deleteVisitor(visitor)
        return Response(success: true)
    }

}

final class UITestParkingClient: ParkingClient {

    func get() async throws -> ParkingResponse {
        let backend = UITestBackend.shared
        return ParkingResponse(active: backend.active, scheduled: backend.scheduled)
    }

    func start(visitor: Visitor, timeMinutes: Int, start: Date, productId: Int, zoneId: Int, parkingMeterId: Int) async throws -> Response {
        UITestBackend.shared.startParking(visitor: visitor, timeMinutes: timeMinutes, start: start)
        return Response(success: true)
    }

    func stop(_ parking: Parking) async throws -> Response {
        UITestBackend.shared.stopParking(parking)
        return Response(success: true)
    }

    func history() async throws -> HistoryResponse {
        HistoryResponse(history: [])
    }

}

final class UITestPaymentClient: PaymentClient {

    func payment(amount: Int, brand: String) async throws -> PaymentResponse {
        PaymentResponse(url: "https://example.com/payment")
    }

    func complete(transactionId: String, data: String) async throws -> Response {
        Response(success: true)
    }

    func status(_ transactionId: String) async throws -> StatusResponse {
        StatusResponse(status: "success")
    }

}

final class UITestGeoClient: GeoClient {

    func parkingMeters(location: CLLocationCoordinate2D) async throws -> [ParkingMeter] {
        [ParkingMeter(id: UITestBackend.shared.parkingMeterId,
                      name: "1234",
                      longitude: location.longitude,
                      latitude: location.latitude,
                      distance: 0)]
    }

}

#endif
