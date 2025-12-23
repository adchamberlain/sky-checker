import Foundation

struct ObservationSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let location: ObserverLocation
    let sunsetTime: Date
    let sunriseTime: Date
    var objects: [CelestialObject]
    let lastUpdated: Date
    
    init(id: UUID = UUID(), date: Date, location: ObserverLocation, sunsetTime: Date, sunriseTime: Date, objects: [CelestialObject] = [], lastUpdated: Date = Date()) {
        self.id = id
        self.date = date
        self.location = location
        self.sunsetTime = sunsetTime
        self.sunriseTime = sunriseTime
        self.objects = objects
        self.lastUpdated = lastUpdated
    }
    
    var cacheKey: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return "session_\(df.string(from: date))_\(String(format: "%.2f_%.2f", location.latitude, location.longitude))"
    }
}

