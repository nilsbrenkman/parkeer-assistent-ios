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
        var components = URLComponents()
        components.path = "geo/parking-meters/nearby"
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.latitude)),
            URLQueryItem(name: "lon", value: String(location.longitude)),
        ]
        let path = components.string ?? "geo/parking-meters/nearby"
        return try await ApiClient.client
            .call(
                [ParkingMeter].self,
                path: path,
                method: Method.GET
            )
    }

}
