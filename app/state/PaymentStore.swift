//
//  PaymentStore.swift
//  parkeerassistent
//

import Foundation

@MainActor
class PaymentStore: ObservableObject {

    @Published var isPaymentInProgress: Bool = false

    private let paymentClient: PaymentClient

    init(paymentClient: PaymentClient) {
        self.paymentClient = paymentClient
    }

    func payment(amount: Int, brand: String, onSuccess: ((String) -> Void)) async {
        let response: PaymentResponse
        do {
            response = try await paymentClient.payment(amount: amount, brand: brand)
        } catch {
            Log.error("payment failed: \(error.localizedDescription)")
            return
        }
        isPaymentInProgress = true
        onSuccess(response.url)
    }

}
