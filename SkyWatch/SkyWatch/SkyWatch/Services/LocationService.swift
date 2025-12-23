import Foundation
import CoreLocation
import Combine

enum LocationError: LocalizedError {
    case permissionDenied, permissionRestricted, locationUnknown, networkError, timeout
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Location permission denied"
        case .permissionRestricted: return "Location services restricted"
        case .locationUnknown: return "Unable to determine location"
        case .networkError: return "Network error"
        case .timeout: return "Location request timed out"
        }
    }
}

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: ObserverLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var error: LocationError?

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<ObserverLocation, Error>?
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() { locationManager.requestWhenInUseAuthorization() }
    
    func getCurrentLocation() async throws -> ObserverLocation {
        print("🛰️ getCurrentLocation() called, status: \(authorizationStatus.rawValue)")
        isLoading = true
        defer { isLoading = false }
        
        // If not determined, request permission and wait for user response
        if authorizationStatus == .notDetermined {
            print("🛰️ Status: notDetermined, requesting permission...")
            requestPermission()
            
            // Wait up to 30 seconds for user to respond to permission dialog
            for i in 1...30 {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                print("🛰️ Waiting for permission... attempt \(i), status: \(authorizationStatus.rawValue)")
                if authorizationStatus != .notDetermined {
                    break
                }
            }
            
            // If still not determined after 30 seconds, user probably dismissed or it didn't show
            if authorizationStatus == .notDetermined {
                print("🛰️ Permission dialog may not have appeared. Check Info.plist settings.")
                throw LocationError.permissionDenied
            }
        }
        
        switch authorizationStatus {
        case .denied:
            print("🛰️ Status: denied - go to Settings > SkyChecker > Location to enable")
            throw LocationError.permissionDenied
        case .restricted:
            print("🛰️ Status: restricted")
            throw LocationError.permissionRestricted
        case .authorizedWhenInUse, .authorizedAlways:
            print("🛰️ Status: authorized, requesting location...")
        case .notDetermined:
            print("🛰️ Status: still notDetermined")
            throw LocationError.permissionDenied
        @unknown default:
            print("🛰️ Status: unknown")
            break
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            print("🛰️ Calling requestLocation()...")
            self.locationManager.requestLocation()
            Task {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if self.locationContinuation != nil {
                    print("🛰️ Location request timed out")
                    self.locationContinuation?.resume(throwing: LocationError.timeout)
                    self.locationContinuation = nil
                }
            }
        }
    }
    
    func getPlaceName(for location: CLLocation) async -> String? {
        try? await geocoder.reverseGeocodeLocation(location).first.flatMap {
            [$0.locality, $0.administrativeArea].compactMap { $0 }.joined(separator: ", ")
        }
    }
    
    func validateCoordinates(latitude: String, longitude: String) -> (lat: Double, lon: Double)? {
        guard let lat = Double(latitude), let lon = Double(longitude),
              lat >= -90, lat <= 90, lon >= -180, lon <= 180 else { return nil }
        return (lat, lon)
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            let name = await getPlaceName(for: location)
            let obs = ObserverLocation(from: location, name: name)
            self.currentLocation = obs
            self.locationContinuation?.resume(returning: obs)
            self.locationContinuation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: LocationError.locationUnknown)
            self.locationContinuation = nil
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.authorizationStatus = manager.authorizationStatus }
    }
}

