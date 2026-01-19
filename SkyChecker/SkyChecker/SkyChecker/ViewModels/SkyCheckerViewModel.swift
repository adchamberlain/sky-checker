import Foundation
import Combine
import CoreLocation

@MainActor
class SkyCheckerViewModel: ObservableObject {
    @Published var currentSession: ObservationSession?
    @Published var objects: [CelestialObject] = []
    @Published var selectedDate = Date()
    @Published var location: ObserverLocation?
    @Published var sunsetTime: Date?
    @Published var sunriseTime: Date?
    @Published var polarCondition: PolarCondition = .normal
    @Published var isLoading = false
    @Published var isUsingManualLocation = false
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var manualLatitude = ""
    @Published var manualLongitude = ""
    @Published var meteorShowerStatus: MeteorShowerStatus?
    
    private let locationService: LocationService
    private let sunsetService: SunsetService
    private let horizonsService: HorizonsAPIService
    private let deepSkyService: DeepSkyCalculationService
    private let issService: ISSService
    private let meteorShowerService: MeteorShowerService
    private let cacheService: CacheService
    private var cancellables = Set<AnyCancellable>()
    private var isRefreshing = false
    private var isFetchingData = false

    init(locationService: LocationService? = nil, sunsetService: SunsetService? = nil, horizonsService: HorizonsAPIService? = nil, deepSkyService: DeepSkyCalculationService? = nil, issService: ISSService? = nil, meteorShowerService: MeteorShowerService? = nil, cacheService: CacheService? = nil) {
        self.locationService = locationService ?? LocationService()
        self.sunsetService = sunsetService ?? SunsetService()
        self.horizonsService = horizonsService ?? HorizonsAPIService()
        self.deepSkyService = deepSkyService ?? DeepSkyCalculationService()
        self.issService = issService ?? ISSService()
        self.meteorShowerService = meteorShowerService ?? MeteorShowerService()
        self.cacheService = cacheService ?? .shared
        self.objects = CelestialObject.solarSystemObjects + CelestialObject.messierObjects + CelestialObject.satelliteObjects
    }
    
    func initialize() async {
        isLoading = true
        let defaultLocation = ObserverLocation.sanFrancisco
        self.location = defaultLocation
        self.isUsingManualLocation = true
        await loadData()
        
        Task {
            if let loc = try? await locationService.getCurrentLocation() {
                await MainActor.run {
                    if self.isUsingManualLocation && self.location?.name == "San Francisco, CA" {
                        self.location = loc
                        self.isUsingManualLocation = false
                    }
                }
            }
        }
    }
    
    func loadData() async {
        guard let location = location else { return }
        guard !isFetchingData else {
            print("⚠️ loadData skipped - already fetching")
            return
        }
        isLoading = true
        isFetchingData = true
        
        // Clear any old cached data to ensure fresh API fetch
        cacheService.clearAllCache()
        print("🗑️ Cache cleared, fetching fresh data...")
        print("📍 Location: \(location.displayString) (\(location.latitude), \(location.longitude))")

        // Detect polar conditions
        polarCondition = sunsetService.detectPolarCondition(for: selectedDate, at: location)

        // Check for upcoming meteor showers
        meteorShowerStatus = meteorShowerService.getShowerStatus(for: selectedDate)

        // Get observation window (sunset tonight → sunrise tomorrow)
        let window: (start: Date, end: Date)
        if let w = sunsetService.getObservationWindow(for: selectedDate, at: location) {
            window = w
        } else {
            // No normal sunrise/sunset - check why
            let cal = Calendar.current
            var comp = cal.dateComponents([.year, .month, .day], from: selectedDate)

            switch polarCondition {
            case .polarNight:
                // Sun below horizon all day - use full 24-hour period for observation
                print("🌑 Polar night detected - sun below horizon all day")
                comp.hour = 0
                comp.minute = 0
                let start = cal.date(from: comp) ?? selectedDate
                window = (start, cal.date(byAdding: .day, value: 1, to: start) ?? selectedDate)

            case .midnightSun:
                // Sun above horizon all day - not ideal for stargazing
                print("☀️ Midnight sun detected - sun above horizon all day")
                comp.hour = 0
                comp.minute = 0
                let start = cal.date(from: comp) ?? selectedDate
                window = (start, cal.date(byAdding: .day, value: 1, to: start) ?? selectedDate)

            case .normal:
                // This shouldn't happen if calculation failed, but provide fallback
                print("⚠️ Normal condition but no sunrise/sunset calculated - using 6 PM to 6 AM")
                comp.hour = 18
                let start = cal.date(from: comp) ?? selectedDate
                window = (start, cal.date(byAdding: .hour, value: 12, to: start) ?? selectedDate)
            }
        }

        // Store sunset/sunrise correctly: window.start = sunset, window.end = sunrise
        self.sunsetTime = window.start
        self.sunriseTime = window.end
        
        print("🌙 Tonight's window:")
        print("   Sunset: \(SunsetService.formatTime(window.start)) (\(window.start))")
        print("   Sunrise: \(SunsetService.formatTime(window.end)) (\(window.end))")
        
        isLoading = false
        
        do {
            // Split objects into different categories
            let solarSystemObjects = objects.filter { $0.type == .planet || $0.type == .moon }
            let deepSkyObjects = objects.filter { $0.type == .messier }
            let satelliteObjects = objects.filter { $0.type == .satellite }

            print("🚀 Starting fetch for \(objects.count) objects (\(solarSystemObjects.count) API, \(deepSkyObjects.count) local, \(satelliteObjects.count) satellites)...")

            // Fetch solar system objects from NASA Horizons API
            var data = try await horizonsService.fetchAllEphemeris(objects: solarSystemObjects, location: location, startTime: window.start, endTime: window.end)

            // Calculate deep sky objects locally
            for obj in deepSkyObjects {
                if let ra = obj.rightAscension, let dec = obj.declination {
                    let ephemeris = deepSkyService.calculateEphemeris(ra: ra, dec: dec, location: location, startTime: window.start, endTime: window.end)
                    data[obj.id] = ephemeris
                    print("🌌 Calculated \(obj.name): transit alt=\(String(format: "%.1f", ephemeris.transitAltitude ?? -90))°")
                }
            }

            // Fetch ISS passes
            for obj in satelliteObjects {
                if obj.id == "iss" {
                    do {
                        let ephemeris = try await issService.fetchISSPasses(location: location, startTime: window.start, endTime: window.end)
                        data[obj.id] = ephemeris
                    } catch {
                        print("⚠️ ISS fetch failed: \(error.localizedDescription)")
                        // Continue without ISS data - don't fail the whole load
                    }
                }
            }

            print("✅ Data ready for \(data.count) objects")
            
            let midnight = sunsetService.getMidnight(for: selectedDate)
            updateObjects(with: data, window: window, midnight: midnight)
            
            // Log results
            print("📝 Tonight's visibility:")
            for obj in objects.sorted(by: { ($0.isVisible ? 0 : 1) < ($1.isVisible ? 0 : 1) }) {
                let status = obj.visibilityStatus?.displayText ?? "unknown"
                let riseStr = obj.riseTime.map { SunsetService.formatTime($0) } ?? "—"
                let setStr = obj.setTime.map { SunsetService.formatTime($0) } ?? "—"
                print("   \(obj.name): \(status) | Rise: \(riseStr) | Set: \(setStr)")
            }
            
            let session = ObservationSession(date: selectedDate, location: location, sunsetTime: window.start, sunriseTime: window.end, objects: objects)
            self.currentSession = session
            cacheService.saveSession(session)
            print("💾 Session saved")
        } catch {
            print("❌ API Error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isFetchingData = false
    }
    
    func setManualLocation() {
        guard let coords = locationService.validateCoordinates(latitude: manualLatitude, longitude: manualLongitude) else {
            errorMessage = "Invalid coordinates"
            showingError = true
            return
        }
        location = ObserverLocation(latitude: coords.lat, longitude: coords.lon, name: "Manual: \(String(format: "%.2f°, %.2f°", coords.lat, coords.lon))")
        isUsingManualLocation = true
        Task { await loadData() }
    }
    
    func useGPSLocation() async {
        print("🛰️ useGPSLocation() called")
        print("🛰️ Current auth status: \(locationService.authorizationStatus.rawValue)")
        isLoading = true
        do {
            print("🛰️ Requesting location...")
            let loc = try await locationService.getCurrentLocation()
            self.location = loc
            self.isUsingManualLocation = false
            print("📍 GPS location received: \(loc.displayString)")
            await loadData()
        } catch {
            print("❌ GPS error: \(error)")
            errorMessage = "Could not get GPS location: \(error.localizedDescription)"
            showingError = true
            isLoading = false
        }
    }

    func refreshData() async {
        // Prevent multiple simultaneous refreshes
        guard !isRefreshing && !isLoading && !isFetchingData else {
            print("🔄 Refresh skipped - already loading")
            return
        }
        
        print("🔄 Pull-to-refresh triggered")
        isRefreshing = true
        
        // Use a detached task to prevent iOS from cancelling the API calls
        // when the refresh gesture ends
        await Task.detached { @MainActor [weak self] in
            guard let self = self else { return }
            self.cacheService.clearAllCache()
            await self.loadData()
        }.value
        
        isRefreshing = false
    }
    
    var sortedObjects: [CelestialObject] {
        objects.sorted { ($0.isVisible ? 0 : 1, $0.riseTime ?? .distantFuture) < ($1.isVisible ? 0 : 1, $1.riseTime ?? .distantFuture) }
    }
    
    // Count objects that are visible now OR will rise later tonight
    var visibleCount: Int {
        objects.filter {
            $0.visibilityStatus == .visible || $0.visibilityStatus == .notYetRisen
        }.count
    }
    var formattedSunset: String {
        switch polarCondition {
        case .polarNight:
            return "Polar Night"
        case .midnightSun:
            return "Midnight Sun"
        case .normal:
            return sunsetTime.map { SunsetService.formatTime($0) } ?? "—"
        }
    }
    var formattedSunrise: String {
        switch polarCondition {
        case .polarNight:
            return "(sun always below horizon)"
        case .midnightSun:
            return "(sun always above horizon)"
        case .normal:
            return sunriseTime.map { SunsetService.formatTime($0) } ?? "—"
        }
    }
    
    private func updateObjects(with data: [String: EphemerisData], window: (start: Date, end: Date), midnight: Date) {
        let sunset = window.start
        let sunrise = window.end
        
        print("🔄 Updating \(data.count) objects with API data")
        print("   Sunset: \(sunset), Sunrise: \(sunrise), Midnight: \(midnight)")
        
        for i in objects.indices {
            let objectId = objects[i].id
            guard let d = data[objectId] else {
                // API call failed for this object - keep previous status if we have one
                // Only set to belowHorizon if we've never had data for it
                if objects[i].visibilityStatus == nil {
                    print("⚠️ No data for \(objects[i].name) (id: \(objectId)) - API failed, no previous data")
                    objects[i].visibilityStatus = .belowHorizon
                } else {
                    print("⚠️ No data for \(objects[i].name) (id: \(objectId)) - API failed, keeping previous status: \(objects[i].visibilityStatus?.displayText ?? "unknown")")
                }
                continue
            }
            
            // Store the raw data
            objects[i].riseTime = d.riseTime
            objects[i].setTime = d.setTime
            objects[i].transitTime = d.transitTime
            objects[i].riseAzimuth = d.riseAzimuth
            objects[i].setAzimuth = d.setAzimuth
            objects[i].transitAltitude = d.transitAltitude
            objects[i].transitAzimuth = d.transitAzimuth
            objects[i].currentAltitude = d.currentAltitude
            objects[i].currentAzimuth = d.currentAzimuth
            objects[i].lastUpdated = Date()
            
            // Handle moon phase
            if objects[i].type == .moon, let ill = d.illumination {
                objects[i].illuminationPercent = ill
                objects[i].moonPhase = MoonPhase.from(illumination: ill, isWaxing: (d.sunElongation ?? 0) < 180)
            }
            
            // Determine visibility status based on CURRENT position
            let currentAltitude = d.currentAltitude ?? -90  // Current altitude
            let currentTime = Date()
            let hasTransit = d.transitTime != nil && (d.transitAltitude ?? 0) > 0

            print("📍 \(objects[i].name): currentAlt=\(String(format: "%.1f", currentAltitude))°, rise=\(d.riseTime.map { SunsetService.formatTime($0) } ?? "nil"), set=\(d.setTime.map { SunsetService.formatTime($0) } ?? "nil"), transit=\(d.transitTime.map { SunsetService.formatTime($0) } ?? "nil")")

            // Determine status based on current altitude
            if currentAltitude > 0 {
                // Object is currently above horizon - VISIBLE NOW
                if let setTime = d.setTime, currentTime < setTime {
                    print("   → Currently visible, sets at \(SunsetService.formatTime(setTime))")
                    objects[i].visibilityStatus = .visible
                } else if let setTime = d.setTime, currentTime >= setTime {
                    // Already set
                    print("   → Already set at \(SunsetService.formatTime(setTime))")
                    objects[i].visibilityStatus = .alreadySet
                } else {
                    // No set time - visible all night or circumpolar
                    print("   → Currently visible, no set time (circumpolar or up all night)")
                    objects[i].visibilityStatus = .visible
                }
            } else if let riseTime = d.riseTime {
                // Object is below horizon - check if it will rise
                if currentTime < riseTime {
                    // Not yet risen
                    print("   → Not yet risen, rises at \(SunsetService.formatTime(riseTime))")
                    objects[i].visibilityStatus = .notYetRisen
                } else {
                    // Rise time has passed but altitude is negative - likely already set
                    if let setTime = d.setTime, currentTime >= setTime {
                        print("   → Already set at \(SunsetService.formatTime(setTime))")
                        objects[i].visibilityStatus = .alreadySet
                    } else {
                        // Edge case: rise time passed but still below horizon
                        print("   → Below horizon (edge case)")
                        objects[i].visibilityStatus = .belowHorizon
                    }
                }
            } else if hasTransit {
                // Has a transit but no rise - might be circumpolar or already up
                print("   → Has transit but no rise detected")
                objects[i].visibilityStatus = .visible
            } else {
                // Object never gets above horizon
                print("   → Below horizon all night")
                objects[i].visibilityStatus = .belowHorizon
            }
            
            print("   Status: \(objects[i].visibilityStatus?.displayText ?? "unknown")")
        }
        
        let visibleNow = objects.filter { $0.visibilityStatus == .visible }.count
        let risesLater = objects.filter { $0.visibilityStatus == .notYetRisen }.count
        print("✨ Visible now: \(visibleNow), Rises later: \(risesLater)")
    }
}

