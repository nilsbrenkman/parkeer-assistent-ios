//
//  Model.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 22/06/2021.
//

import Foundation

struct Response: Codable {
    var success: Bool
    var message: String?
}

struct LoginRequest: Codable {
    var username: String
    var password: String
}

struct UserResponse: Codable {
    var balance: String
    var hourRate: Double
    var productId: Int
    var zoneId: Int
    var parkingMeterId: Int
    var regime: Regime
}

struct BalanceResponse: Codable {
    var balance: String
}

struct RegimeResponse: Codable {
    var hourRate: Double
    var zoneId: Int
    var regime: Regime
}

struct IdealResponse: Codable {
    var amounts: [String]
    var issuers: [Issuer]
}

struct Issuer: Codable {
    var issuerId: String
    var name: String
}

struct PaymentRequest: Codable {
    var amount: Int
    var brand: String
    var lang: String
}

struct PaymentResponse: Codable {
    var url: String
}

struct CompleteRequest: Codable {
    var transactionId: String
    var data: String
}

struct StatusResponse: Codable {
    var status: String
}

struct Parking: Codable, Hashable, Comparable {
    var id: Int
    var license: String
    var startTime: String
    var endTime: String
    var cost: Double

    static func < (lhs: Parking, rhs: Parking) -> Bool {
        lhs.id < rhs.id
    }
}

struct ParkingResponse: Codable, Equatable {
    var active: [Parking]
    var scheduled: [Parking]

    static func == (lhs: ParkingResponse, rhs: ParkingResponse) -> Bool {
        lhs.active.sorted() == rhs.active.sorted() && lhs.scheduled.sorted() == rhs.scheduled.sorted()
    }
}

struct AddParkingRequest: Codable {
    var license: String
    var timeMinutes: Int
    var start: String?
    var productId: Int
    var zoneId: Int
    var parkingMeterId: Int
}

struct Visitor: Codable, Hashable, Comparable {
    var id: Int
    var license: String
    var formattedLicense: String
    var name: String?

    static func < (lhs: Visitor, rhs: Visitor) -> Bool {
        guard let ln = lhs.name else {
            guard rhs.name != nil else {
                return lhs.license < rhs.license
            }
            return false
        }
        guard let rn = rhs.name else {
            return true
        }
        return ln < rn
    }
}

struct VisitorResponse: Codable {
    var visitors: [Visitor]
}

struct AddVisitorRequest: Codable {
    var license: String
    var name: String
}

struct HistoryResponse: Codable {
    var history: [History]
}

struct History: Codable, Hashable {
    var id: Int
    var license: String
    var startTime: String
    var endTime: String
    var cost: Double

    var date: Date { try! Util.parseDate(startTime) }
}

struct Regime: Codable {
    var days: [RegimeDay]
}

struct RegimeDay: Codable {
    var weekday: String
    var startTime: String
    var endTime: String
}

struct ParkingMeter: Codable {
    var id: Int
    var name: String
    var longitude: Double
    var latitude: Double
    var distance: Double
}
