//
//  PaymentStoreTest.swift
//  parkeerassistentTests
//

@testable import app
import Testing

@MainActor
struct PaymentStoreTest {

    @Test func paymentSetsInProgressAndDeliversUrlOnSuccess() async {
        let client = MockPaymentClient()
        client.paymentResult = .success(PaymentResponse(url: "https://pay.test/123"))
        let store = PaymentStore(paymentClient: client)

        var deliveredUrl: String?
        await store.payment(amount: 500, brand: "ideal") { url in
            deliveredUrl = url
        }

        #expect(deliveredUrl == "https://pay.test/123")
        #expect(store.isPaymentInProgress)
    }

    @Test func paymentDoesNotSetInProgressOnError() async {
        let client = MockPaymentClient()
        client.paymentResult = .failure(ClientError.NoHttpResponse)
        let store = PaymentStore(paymentClient: client)

        var deliveredUrl: String?
        await store.payment(amount: 500, brand: "ideal") { url in
            deliveredUrl = url
        }

        #expect(deliveredUrl == nil)
        #expect(store.isPaymentInProgress == false)
    }
}
