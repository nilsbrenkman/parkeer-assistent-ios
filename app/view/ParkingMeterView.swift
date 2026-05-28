//
//  ParkingMeterView.swift
//  app
//
//  Created by Nils Brenkman on 11/11/2025.
//

import SwiftUI
import MapKit

struct ParkingMeterView: View {
    
    @EnvironmentObject var parkingMeter: ParkingMeterStore
    
    var onSelect: (ParkingMeter) -> Void
    
    @State private var locationAuthorizationListener: LocationAuthorizationListener? = nil
    @State private var isAppearing: Bool = true

    private let locationManager = CLLocationManager()
    private let geoClient = try? ClientManager.instance.get(GeoClient.self)
    
    var body: some View {
        Map(position: $parkingMeter.position, bounds: .amsterdam, interactionModes: [.pan, .zoom, .rotate]) {
            UserAnnotation()
            
            ForEach(parkingMeter.parkingMeters, id: \.id) { meter in
                Annotation("", coordinate: meter.coordinate(), anchor: .center) {
                    Text("\(String(meter.id))")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .background {
                            RoundedRectangle(cornerRadius: Constants.radius.normal, style: .continuous)
                                .fill(Color.ui.header)
                                .padding(-10)
                                .shadow(color: .black, radius: 1, y: 0.5)
                        }
                        .onTapGesture {
                            onSelect(meter)
                        }
                }
            }
        }
        .onMapCameraChange { context in
            if isAppearing { return }
            let center = context.region.center
            if let last = parkingMeter.lastLocation {
                let distance = center.distance(to: last)
                if distance < 50 {
                    return
                }
            }
            parkingMeter.lastLocation = center
            Task {
                parkingMeter.parkingMeters = try await self.geoClient?.parkingMeters(location: center) ?? []
            }
        }
        .mapControls {
            if (locationManager.authorizationStatus == .authorizedWhenInUse) {
                MapUserLocationButton()
            }
            MapCompass()
        }
        .onAppear() {
            if (locationAuthorizationListener == nil) {
                self.locationAuthorizationListener = LocationAuthorizationListener(self.updateLocation)
                self.locationManager.delegate = self.locationAuthorizationListener
            }
            if (parkingMeter.lastLocation == nil) {
                if (self.locationManager.authorizationStatus == .authorizedWhenInUse) {
                    self.locationManager.requestLocation()
                } else {
                    self.locationManager.requestWhenInUseAuthorization()
                }
            }
            isAppearing = false
        }
    }
    
    func updateLocation(coordinate: CLLocationCoordinate2D) {
        parkingMeter.position = .camera(MapCamera(
            centerCoordinate: coordinate,
            distance: 1000,
            heading: 0,
            pitch: 0
        ))
    }
    
    class LocationAuthorizationListener: NSObject, CLLocationManagerDelegate {
        
        private let onLocationChanged: (CLLocationCoordinate2D) -> Void
        
        init(_ onLocationChanged: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onLocationChanged = onLocationChanged
        }
        
        func locationManager(_ manager: CLLocationManager,
                             didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .authorizedWhenInUse {
                if let location = manager.location {
                    onLocationChanged(location.coordinate)
                }
            }
        }
        
        func locationManager(_ manager: CLLocationManager,
                             didUpdateLocations locations: [CLLocation]) {
            onLocationChanged(manager.location!.coordinate)
        }
        
        func locationManager(_ manager: CLLocationManager,
                             didFailWithError error: any Error) {
            Log.error("locationManager didFailWithError: \(error.localizedDescription)")
        }
        
    }
    
}

extension CLLocationCoordinate2D {
    static let amsterdam = CLLocationCoordinate2D(latitude: 52.371444, longitude: 4.896732)
    
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let a = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b)   // meters
    }
}

extension MapCameraBounds {
    static let amsterdam = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: .amsterdam,
            span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
        ),
        minimumDistance: 250,
        maximumDistance: 50000
    )
}

extension ParkingMeter {
    func coordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    ParkingMeterView(onSelect: { _ in })
}
