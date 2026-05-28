//
//  LoginClient.swift
//  parkeerassistent
//
//  Created by Nils Brenkman on 22/06/2021.
//

import Foundation
import CoreLocation

protocol GeoClient {
    func parkingMeters(location: CLLocationCoordinate2D) async throws -> [ParkingMeter]
}

class GeoClientApi: GeoClient {

    static let client = GeoClientApi()

    private init() {
        //
    }

    func parkingMeters(location: CLLocationCoordinate2D) async throws -> [ParkingMeter] {
        return try await ApiClient.client
            .call(
                [ParkingMeter].self,
                path: "geo/parking-meters/nearby?lat=\(location.latitude)&lon=\(location.longitude)",
                method: Method.GET
            )
    }

}
