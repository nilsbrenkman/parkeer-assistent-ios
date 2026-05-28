//
//  UserClient.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 22/06/2021.
//

import Foundation

protocol UserClient {
    func get() async throws -> UserResponse
    func balance() async throws -> BalanceResponse
    func regime(parkingMeterId: Int) async throws -> RegimeResponse
}

class UserClientApi: UserClient {

    static let client = UserClientApi()

    private init() {
        //
    }

    func get() async throws -> UserResponse {
        try await ApiClient.client.call(UserResponse.self, path: "user", method: Method.GET)
    }

    func balance() async throws -> BalanceResponse {
        try await ApiClient.client.call(BalanceResponse.self, path: "user/balance", method: Method.GET)
    }

    func regime(parkingMeterId: Int) async throws -> RegimeResponse {
        try await ApiClient.client.call(RegimeResponse.self, path: "user/regime/\(parkingMeterId)", method: Method.GET)
    }

}
