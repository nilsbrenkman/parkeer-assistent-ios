//
//  PaymentClient.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 20/08/2021.
//

import Foundation
import os

protocol PaymentClient {
    func payment(amount: Int, brand: String) async throws -> PaymentResponse
    func complete(transactionId: String, data: String) async throws -> Response
    func status(_ transactionId: String) async throws -> StatusResponse
}

class PaymentClientApi: PaymentClient {

    static let client = PaymentClientApi()

    private init() {
        //
    }

    func payment(amount: Int, brand: String) async throws -> PaymentResponse {
        let body = PaymentRequest(amount: amount, brand: brand, lang: "NL")
        return try await ApiClient.client.call(PaymentResponse.self, path: "payment", method: Method.POST, body: body)
    }

    func complete(transactionId: String, data: String) async throws -> Response {
        let body = CompleteRequest(transactionId: transactionId, data: data)
        return try await ApiClient.client.call(Response.self, path: "payment/complete", method: Method.POST, body: body)
    }

    func status(_ transactionId: String) async throws -> StatusResponse {
        try await ApiClient.client.call(StatusResponse.self, path: "payment/\(transactionId)", method: Method.GET)
    }

}
