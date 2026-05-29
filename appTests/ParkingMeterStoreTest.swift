//
//  ParkingMeterStoreTest.swift
//  parkeerassistentTests
//

@testable import app
import CoreLocation
import Testing

@MainActor
struct ParkingMeterStoreTest {

    private let location = CLLocationCoordinate2D(latitude: 52.37, longitude: 4.89)

    @Test func fetchNearbyPopulatesParkingMeters() async {
        let client = MockGeoClient()
        let meter = ParkingMeter(id: 42, name: "Test", longitude: 4.89, latitude: 52.37, distance: 10)
        client.parkingMetersResult = .success([meter])
        let store = ParkingMeterStore(geoClient: client)

        await store.fetchNearby(location)

        #expect(client.parkingMetersCalls.count == 1)
        #expect(store.parkingMeters.count == 1)
        #expect(store.parkingMeters.first?.id == 42)
    }

    @Test func fetchNearbyLeavesStateUnchangedOnError() async {
        let client = MockGeoClient()
        client.parkingMetersResult = .failure(ClientError.NoHttpResponse)
        let store = ParkingMeterStore(geoClient: client)

        await store.fetchNearby(location)

        #expect(store.parkingMeters.isEmpty)
    }
}
