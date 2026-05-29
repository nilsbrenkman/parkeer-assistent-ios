//
//  MockClients.swift
//  parkeerassistentTests
//

@testable import app
import CoreLocation
import Foundation

final class MockLoginClient: LoginClient, @unchecked Sendable {
    var loggedInResult: Result<Response, Error> = .success(Response(success: false))
    var loginResult: Result<Response, Error> = .success(Response(success: true))
    var logoutResult: Result<Response, Error> = .success(Response(success: true))

    private(set) var loginCalls: [(username: String, password: String)] = []
    private(set) var logoutCallCount = 0

    func loggedId() async throws -> Response { try loggedInResult.get() }

    func login(username: String, password: String) async throws -> Response {
        loginCalls.append((username, password))
        return try loginResult.get()
    }

    func logout() async throws -> Response {
        logoutCallCount += 1
        return try logoutResult.get()
    }
}

final class MockUserClient: UserClient, @unchecked Sendable {
    var getResult: Result<UserResponse, Error> = .success(
        UserResponse(balance: "10,00", hourRate: 1.5, productId: 1, zoneId: 2, parkingMeterId: 3, regime: Regime(days: []))
    )
    var balanceResult: Result<BalanceResponse, Error> = .success(BalanceResponse(balance: "10,00"))
    var regimeResult: Result<RegimeResponse, Error> = .success(
        RegimeResponse(hourRate: 2.0, zoneId: 99, regime: Regime(days: []))
    )

    func get() async throws -> UserResponse { try getResult.get() }
    func balance() async throws -> BalanceResponse { try balanceResult.get() }
    func regime(parkingMeterId: Int) async throws -> RegimeResponse { try regimeResult.get() }
}

final class MockParkingClient: ParkingClient, @unchecked Sendable {
    var getResult: Result<ParkingResponse, Error> = .success(ParkingResponse(active: [], scheduled: []))
    var startResult: Result<Response, Error> = .success(Response(success: true))
    var stopResult: Result<Response, Error> = .success(Response(success: true))
    var historyResult: Result<HistoryResponse, Error> = .success(HistoryResponse(history: []))

    private(set) var stopCalls: [Parking] = []
    private(set) var getCallCount = 0

    func get() async throws -> ParkingResponse {
        getCallCount += 1
        return try getResult.get()
    }

    func start(visitor: Visitor, timeMinutes: Int, start: Date, productId: Int, zoneId: Int, parkingMeterId: Int) async throws -> Response {
        try startResult.get()
    }

    func stop(_ parking: Parking) async throws -> Response {
        stopCalls.append(parking)
        return try stopResult.get()
    }

    func history() async throws -> HistoryResponse { try historyResult.get() }
}

final class MockVisitorClient: VisitorClient, @unchecked Sendable {
    var getResult: Result<VisitorResponse, Error> = .success(VisitorResponse(visitors: []))
    var addResult: Result<Response, Error> = .success(Response(success: true))
    var deleteResult: Result<Response, Error> = .success(Response(success: true))

    private(set) var addCalls: [(license: String, name: String)] = []
    private(set) var deleteCalls: [Visitor] = []

    func get() async throws -> VisitorResponse { try getResult.get() }

    func add(license: String, name: String) async throws -> Response {
        addCalls.append((license, name))
        return try addResult.get()
    }

    func delete(_ visitor: Visitor) async throws -> Response {
        deleteCalls.append(visitor)
        return try deleteResult.get()
    }
}

final class MockGeoClient: GeoClient, @unchecked Sendable {
    var parkingMetersResult: Result<[ParkingMeter], Error> = .success([])

    private(set) var parkingMetersCalls: [CLLocationCoordinate2D] = []

    func parkingMeters(location: CLLocationCoordinate2D) async throws -> [ParkingMeter] {
        parkingMetersCalls.append(location)
        return try parkingMetersResult.get()
    }
}

final class MockPaymentClient: PaymentClient, @unchecked Sendable {
    var paymentResult: Result<PaymentResponse, Error> = .success(PaymentResponse(url: "https://example.com/pay"))
    var completeResult: Result<Response, Error> = .success(Response(success: true))
    var statusResult: Result<StatusResponse, Error> = .success(StatusResponse(status: "PAID"))

    func payment(amount: Int, brand: String) async throws -> PaymentResponse { try paymentResult.get() }
    func complete(transactionId: String, data: String) async throws -> Response { try completeResult.get() }
    func status(_ transactionId: String) async throws -> StatusResponse { try statusResult.get() }
}
