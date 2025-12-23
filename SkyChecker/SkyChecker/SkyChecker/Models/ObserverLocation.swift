import Foundation
import CoreLocation

struct ObserverLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let name: String?
    
    init(latitude: Double, longitude: Double, altitude: Double = 0, name: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.name = name
    }
    
    init(from location: CLLocation, name: String? = nil) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.name = name
    }
    
    var horizonsSiteCoord: String {
        String(format: "%.4f,%.4f,%.1f", longitude, latitude, altitude / 1000.0)
    }
    
    var displayString: String {
        if let name = name { return name }
        let latDir = latitude >= 0 ? "N" : "S"
        let lonDir = longitude >= 0 ? "E" : "W"
        return String(format: "%.2f°%@ %.2f°%@", abs(latitude), latDir, abs(longitude), lonDir)
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension ObserverLocation {
    static let sanFrancisco = ObserverLocation(latitude: 37.7749, longitude: -122.4194, altitude: 16, name: "San Francisco, CA")
}

