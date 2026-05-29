//
//  UserStoreTest.swift
//  parkeerassistentTests
//

@testable import app
import Testing

@MainActor
struct UserStoreTest {

    @Test func getUserPopulatesPublishedValues() async {
        let client = MockUserClient()
        client.getResult = .success(
            UserResponse(balance: "12,34", hourRate: 1.0, productId: 7, zoneId: 8, parkingMeterId: 9, regime: Regime(days: []))
        )
        let store = UserStore(userClient: client)

        await store.getUser({ })

        #expect(store.balance == "12,34")
        #expect(store.productId == 7)
        #expect(store.zoneId == 8)
        #expect(store.parkingMeterId == 9)
    }

    @Test func getUserLeavesStateUnchangedOnError() async {
        let client = MockUserClient()
        client.getResult = .failure(ClientError.NoHttpResponse)
        let store = UserStore(userClient: client)

        await store.getUser({ })

        #expect(store.balance == nil)
        #expect(store.productId == nil)
    }

    @Test func getBalanceUpdatesBalance() async {
        let client = MockUserClient()
        client.balanceResult = .success(BalanceResponse(balance: "5,55"))
        let store = UserStore(userClient: client)

        await store.getBalance()

        #expect(store.balance == "5,55")
    }

    @Test func resetClearsAllPublishedState() async {
        let client = MockUserClient()
        let store = UserStore(userClient: client)
        await store.getUser({ })
        store.isLoaded = true

        store.reset()

        #expect(store.balance == nil)
        #expect(store.productId == nil)
        #expect(store.zoneId == nil)
        #expect(store.parkingMeterId == nil)
        #expect(store.regime == nil)
        #expect(store.isLoaded == false)
        #expect(store.timeBalance == 0)
    }
}
