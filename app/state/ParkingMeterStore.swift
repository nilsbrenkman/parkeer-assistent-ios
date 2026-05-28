//
//  ParkingMeterStore.swift
//  parkeerassistent
//

import Foundation
import MapKit
import SwiftUI

@MainActor
class ParkingMeterStore: ObservableObject {

    @Published var position: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: .amsterdam,
        distance: 1000,
        heading: 0,
        pitch: 0
    ))
    @Published var parkingMeters: [ParkingMeter] = []
    @Published var lastLocation: CLLocationCoordinate2D? = nil

}
