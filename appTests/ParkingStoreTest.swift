//
//  ParkingStoreTest.swift
//  parkeerassistentTests
//

@testable import app
import Testing

@MainActor
struct ParkingStoreTest {

    private func makeParking(id: Int) -> Parking {
        Parking(id: id, license: "AB-123-C", startTime: "2026-01-01T09:00:00+00:00", endTime: "2026-01-01T10:00:00+00:00", cost: 1.5)
    }

    @Test func getParkingSetsStateOnSuccess() async {
        let client = MockParkingClient()
        client.getResult = .success(ParkingResponse(active: [makeParking(id: 1)], scheduled: []))
        let store = ParkingStore(parkingClient: client)

        await store.getParking()

        #expect(store.parking?.active.count == 1)
        #expect(store.parking?.active.first?.id == 1)
    }

    @Test func getParkingLeavesStateUnchangedOnError() async {
        let client = MockParkingClient()
        client.getResult = .failure(ClientError.NoHttpResponse)
        let store = ParkingStore(parkingClient: client)

        await store.getParking()

        #expect(store.parking == nil)
    }

    @Test func stopParkingHandlesNilCurrentStateWithoutCrashing() async {
        // Regression: stopParking previously force-unwrapped self.parking.
        let client = MockParkingClient()
        let store = ParkingStore(parkingClient: client)
        let user = UserStore(userClient: MockUserClient())

        await store.stopParking(makeParking(id: 1), user: user)

        #expect(client.stopCalls.count == 1)
        #expect(client.stopCalls.first?.id == 1)
    }

    @Test func getHistoryPopulatesState() async {
        let client = MockParkingClient()
        client.historyResult = .success(HistoryResponse(history: [
            History(id: 1, license: "AB-123-C", startTime: "2026-01-01T09:00:00+00:00", endTime: "2026-01-01T10:00:00+00:00", cost: 1.5)
        ]))
        let store = ParkingStore(parkingClient: client)

        await store.getHistory()

        #expect(store.history?.count == 1)
        #expect(store.history?.first?.id == 1)
    }

    @Test func getHistoryLeavesStateUnchangedOnError() async {
        let client = MockParkingClient()
        client.historyResult = .failure(ClientError.NoHttpResponse)
        let store = ParkingStore(parkingClient: client)

        await store.getHistory()

        #expect(store.history == nil)
    }

    @Test func stopParkingRemovesParkingFromState() async {
        let client = MockParkingClient()
        let initial = ParkingResponse(
            active: [makeParking(id: 1), makeParking(id: 2)],
            scheduled: [makeParking(id: 3)]
        )
        client.getResult = .success(initial)
        let store = ParkingStore(parkingClient: client)
        await store.getParking()

        // Make the refresh after stop return an empty list so we can observe the optimistic local update.
        client.getResult = .success(ParkingResponse(active: [], scheduled: []))

        await store.stopParking(makeParking(id: 1), user: UserStore(userClient: MockUserClient()))

        #expect(client.stopCalls.first?.id == 1)
        #expect(store.parking?.active.contains(where: { $0.id == 1 }) == false)
    }
}
