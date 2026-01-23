# SkyChecker Android Build Plan

## Overview

This plan outlines building a native Android version of SkyChecker, an astronomy app that shows tonight's visibility for planets, deep sky objects, the ISS, and meteor showers.

**iOS App Stats:**
- ~3,700 lines of Swift code
- 22 source files
- Pure SwiftUI with MVVM architecture
- No third-party dependencies

---

## Project Setup

### Development Environment
- **IDE:** Android Studio (latest stable)
- **Language:** Kotlin
- **Min SDK:** API 26 (Android 8.0) - covers 95%+ of devices
- **Target SDK:** API 34 (Android 14)
- **Build System:** Gradle with Kotlin DSL

### Dependencies

**Note:** Consider using Gradle Version Catalogs (`libs.versions.toml`) for cleaner dependency management across modules.

```kotlin
// build.gradle.kts
plugins {
    id("com.google.dagger.hilt.android")
    id("com.google.devtools.ksp")
    kotlin("plugin.serialization")
}

dependencies {
    // Jetpack Compose (use latest stable BOM)
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.9.3")

    // ViewModel + Lifecycle
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")

    // Navigation (with type-safe routes)
    implementation("androidx.navigation:navigation-compose:2.8.5")

    // Dependency Injection (Hilt)
    implementation("com.google.dagger:hilt-android:2.53.1")
    ksp("com.google.dagger:hilt-compiler:2.53.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation("com.jakewharton.retrofit:retrofit2-kotlinx-serialization-converter:1.0.0")

    // Location
    implementation("com.google.android.gms:play-services-location:21.3.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // DataStore (for caching)
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // WorkManager (for background updates/notifications)
    implementation("androidx.work:work-runtime-ktx:2.10.0")
    implementation("androidx.hilt:hilt-work:1.2.0")
    ksp("androidx.hilt:hilt-compiler:1.2.0")

    // Image loading
    implementation("io.coil-kt:coil-compose:2.7.0")

    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
    testImplementation("com.google.dagger:hilt-android-testing:2.53.1")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
}
```

---

## Architecture

### Package Structure
```
com.skychecker/
├── MainActivity.kt
├── SkyCheckerApp.kt
├── ui/
│   ├── theme/
│   │   ├── Color.kt
│   │   ├── Theme.kt
│   │   └── Type.kt
│   ├── screens/
│   │   ├── HomeScreen.kt
│   │   ├── ObjectDetailScreen.kt
│   │   ├── LocationSettingsScreen.kt
│   │   ├── WeatherDetailScreen.kt
│   │   └── MeteorShowerScreen.kt
│   └── components/
│       ├── ObjectRow.kt
│       ├── WeatherCard.kt
│       ├── HeaderSection.kt
│       └── TerminalText.kt
├── viewmodel/
│   └── SkyCheckerViewModel.kt
├── data/
│   ├── model/
│   │   ├── CelestialObject.kt
│   │   ├── ObserverLocation.kt
│   │   ├── ObservationSession.kt
│   │   ├── WeatherData.kt
│   │   └── MeteorShower.kt
│   ├── remote/
│   │   ├── HorizonsApi.kt
│   │   ├── WeatherApi.kt
│   │   └── IssApi.kt
│   └── repository/
│       └── SkyRepository.kt
├── domain/
│   ├── DeepSkyCalculationService.kt
│   ├── SunsetService.kt
│   └── MeteorShowerService.kt
├── util/
│   ├── LocationService.kt
│   ├── CacheManager.kt
│   ├── NetworkMonitor.kt
│   └── Extensions.kt
├── worker/
│   ├── MeteorShowerNotificationWorker.kt
│   └── IssPassNotificationWorker.kt
└── di/
    ├── AppModule.kt
    ├── NetworkModule.kt
    └── RepositoryModule.kt
```

---

## Implementation Phases

### Phase 1: Project Foundation

**Tasks:**
1. Create new Android Studio project with Compose
2. Configure Gradle dependencies
3. Set up package structure
4. Create theme with retro terminal aesthetic
   - Dark background (#0D1117 or similar)
   - Green/amber monospace text
   - Custom fonts matching iOS version
5. Set up Hilt dependency injection

**Key Files to Create:**
- `MainActivity.kt` - Single activity entry point
- `SkyCheckerApp.kt` - Compose navigation host (with type-safe routes)
- `ui/theme/*` - Theme configuration
- `di/AppModule.kt` - Hilt module for app-wide dependencies
- `di/NetworkModule.kt` - Hilt module for Retrofit/OkHttp
- `di/RepositoryModule.kt` - Hilt module for repositories

**Hilt Setup:**
```kotlin
// SkyCheckerApplication.kt
@HiltAndroidApp
class SkyCheckerApplication : Application()

// MainActivity.kt
@AndroidEntryPoint
class MainActivity : ComponentActivity()

// di/NetworkModule.kt
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder()
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        })
        .build()

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit = Retrofit.Builder()
        .baseUrl("https://ssd.jpl.nasa.gov/api/")
        .client(okHttpClient)
        .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
        .build()
}
```

**Type-Safe Navigation Setup:**
```kotlin
// Navigation routes using @Serializable
@Serializable object HomeRoute
@Serializable data class ObjectDetailRoute(val objectId: String)
@Serializable object LocationSettingsRoute
@Serializable object WeatherDetailRoute
@Serializable data class MeteorShowerRoute(val showerId: String)

// NavHost with type-safe routes
NavHost(navController, startDestination = HomeRoute) {
    composable<HomeRoute> { HomeScreen(navController) }
    composable<ObjectDetailRoute> { backStackEntry ->
        val route: ObjectDetailRoute = backStackEntry.toRoute()
        ObjectDetailScreen(objectId = route.objectId)
    }
    // ...
}
```

### Phase 2: Data Models

**Port these Swift structs to Kotlin data classes:**

| iOS File | Android File |
|----------|--------------|
| `CelestialObject.swift` | `CelestialObject.kt` |
| `ObserverLocation.swift` | `ObserverLocation.kt` |
| `ObservationSession.swift` | `ObservationSession.kt` |

**Enums to port:**
- `CelestialObjectType` (planet, moon, messier, satellite)
- `MoonPhase` (8 phases with emoji)
- `SkyDirection` (N, NE, E, SE, S, SW, W, NW)
- `VisibilityStatus` (visible, notYetRisen, alreadySet, belowHorizon, tooCloseToSun)
- `DifficultyRating` (nakedEye, binoculars, smallTelescope, largeTelescope)

**Static Data:**
- 8 planets + Moon (with Horizons command IDs)
- 6 Messier objects (M31, M42, M22, M45, M44, M13 with RA/Dec)
- ISS satellite entry

### Phase 3: Core Calculation Services

**Port pure calculation logic (no platform dependencies):**

1. **DeepSkyCalculationService.kt**
   - `calculateEphemeris()` - Main calculation entry point
   - `altitudeAzimuth()` - Spherical trigonometry for alt/az
   - `localSiderealTime()` - LST calculation
   - `julianDate()` - Julian date conversion

   Source: `/Users/andrewchamberlain/github/sky-checker/SkyChecker/SkyChecker/SkyChecker/Services/DeepSkyCalculationService.swift`

2. **SunsetService.kt**
   - `getObservationWindow()` - Calculate sunset→sunrise window
   - `detectPolarCondition()` - Handle polar night/midnight sun
   - `getMidnight()` - Calculate local midnight

   Source: `/Users/andrewchamberlain/github/sky-checker/SkyChecker/SkyChecker/SkyChecker/Services/SunsetService.swift`

3. **MeteorShowerService.kt**
   - Hardcoded meteor shower data (dates, ZHR values)
   - `getShowerStatus()` - Check if shower is active

   Source: `/Users/andrewchamberlain/github/sky-checker/SkyChecker/SkyChecker/SkyChecker/Services/MeteorShowerService.swift`

### Phase 4: API Integrations

**Retrofit interfaces for external APIs:**

1. **HorizonsApi.kt** - NASA JPL Horizons
   - Base URL: `https://ssd.jpl.nasa.gov/api/`
   - Endpoint: `horizons.api` with query parameters
   - Response: Plain text, custom parser needed
   - Retry logic for 429/503 responses

2. **WeatherApi.kt** - Open-Meteo
   - Base URL: `https://api.open-meteo.com/v1/`
   - Endpoint: `forecast`
   - Response: JSON
   - No API key required

3. **IssApi.kt** - ISS Tracking
   - **Primary:** Where the ISS at API (recommended, more reliable)
     - Base URL: `https://api.wheretheiss.at/v1/`
     - Endpoint: `satellites/25544` (current position)
     - Endpoint: `satellites/25544/positions` (future positions)
     - Response: JSON, no API key required
   - **Alternative:** N2YO API
     - Base URL: `https://api.n2yo.com/rest/v1/`
     - Requires free API key
     - More detailed pass predictions
   - **Legacy (deprecated):** Open Notify (`http://api.open-notify.org/`) - unreliable, avoid

**Create SkyRepository.kt:**
- Coordinates all API calls
- Merges results (planets from Horizons, deep sky from local calc, ISS from tracking API)
- Handles caching with DataStore
- Exposes Flow<UiState> to ViewModel
- Implements offline-first pattern with NetworkMonitor

**Offline-First Architecture:**
```kotlin
// NetworkMonitor.kt
@Singleton
class NetworkMonitor @Inject constructor(
    @ApplicationContext private val context: Context
) {
    val isOnline: Flow<Boolean> = callbackFlow {
        val connectivityManager = context.getSystemService<ConnectivityManager>()
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) { trySend(true) }
            override fun onLost(network: Network) { trySend(false) }
        }
        connectivityManager?.registerDefaultNetworkCallback(callback)
        // Initial state
        trySend(connectivityManager?.activeNetwork != null)
        awaitClose { connectivityManager?.unregisterNetworkCallback(callback) }
    }.distinctUntilChanged()
}

// SkyRepository.kt - Offline-first pattern
class SkyRepository @Inject constructor(
    private val horizonsApi: HorizonsApi,
    private val weatherApi: WeatherApi,
    private val issApi: IssApi,
    private val cacheManager: CacheManager,
    private val networkMonitor: NetworkMonitor
) {
    fun getObservationData(date: LocalDate, location: ObserverLocation): Flow<Resource<ObservationSession>> = flow {
        emit(Resource.Loading)

        // Try cache first
        cacheManager.loadSession(date, location)?.let { cached ->
            emit(Resource.Success(cached, fromCache = true))
        }

        // Fetch fresh if online
        networkMonitor.isOnline.first().let { online ->
            if (online) {
                try {
                    val fresh = fetchFromNetwork(date, location)
                    cacheManager.saveSession(fresh)
                    emit(Resource.Success(fresh, fromCache = false))
                } catch (e: Exception) {
                    emit(Resource.Error(e.message ?: "Network error"))
                }
            }
        }
    }
}
```

**UI State for Offline Mode:**
```kotlin
data class SkyUiState(
    // ... existing fields
    val isOffline: Boolean = false,
    val isFromCache: Boolean = false,
    val lastUpdated: LocalDateTime? = null
)
```

### Phase 5: Location Services

**LocationService.kt using Fused Location Provider:**

```kotlin
@Singleton
class LocationService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

    suspend fun getCurrentLocation(): ObserverLocation
    fun validateCoordinates(lat: String, lon: String): Pair<Double, Double>?
}
```

**Required permissions in AndroidManifest.xml:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

**Runtime permission handling in Compose.**

### Phase 6: ViewModel

**SkyCheckerViewModel.kt:**

Port the logic from iOS `SkyCheckerViewModel.swift`:

```kotlin
@HiltViewModel
class SkyCheckerViewModel @Inject constructor(
    private val repository: SkyRepository,
    private val locationService: LocationService,
    private val networkMonitor: NetworkMonitor
) : ViewModel() {

    // UI State
    private val _uiState = MutableStateFlow(SkyUiState())
    val uiState: StateFlow<SkyUiState> = _uiState.asStateFlow()

    // Network connectivity
    val isOnline: StateFlow<Boolean> = networkMonitor.isOnline
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), true)

    // Actions
    fun initialize()
    fun loadData()
    fun setManualLocation(lat: String, lon: String)
    fun useGpsLocation()
    fun refreshData()
    fun setSelectedDate(date: LocalDate)
}

data class SkyUiState(
    val objects: List<CelestialObject> = emptyList(),
    val location: ObserverLocation? = null,
    val selectedDate: LocalDate = LocalDate.now(),
    val sunsetTime: LocalDateTime? = null,
    val sunriseTime: LocalDateTime? = null,
    val weather: WeatherData? = null,
    val meteorShowerStatus: MeteorShowerStatus? = null,
    val isLoading: Boolean = false,
    val error: String? = null,
    val isOffline: Boolean = false,
    val isFromCache: Boolean = false,
    val lastUpdated: LocalDateTime? = null
)
```

### Phase 7: UI Implementation

**Screens to build:**

1. **HomeScreen.kt** (matches `ContentView.swift`)
   - Header with location, date picker, sunset/sunrise times
   - Weather summary card
   - Meteor shower alert (when active)
   - Scrollable list of celestial objects
   - Pull-to-refresh
   - Share button

2. **ObjectDetailScreen.kt** (matches `ObjectDetailView.swift`)
   - Object name and type
   - Current position (altitude, direction)
   - Rise/transit/set times with directions
   - Moon phase (for Moon only)
   - Wikipedia link
   - Share button

3. **LocationSettingsScreen.kt** (matches `LocationSettingsView.swift`)
   - GPS location button
   - Manual coordinate entry (lat/lon fields)
   - Current location display

4. **WeatherDetailScreen.kt** (matches `WeatherDetailView.swift`)
   - Cloud cover breakdown (low/mid/high)
   - Visibility, humidity, wind
   - Observation rating (1-5 stars)

5. **MeteorShowerScreen.kt** (matches `MeteorShowerDetailView.swift`)
   - Shower name and dates
   - Peak date and ZHR
   - Best viewing tips

**Components:**
- `ObjectRow.kt` - List item with visibility status, times
- `TerminalText.kt` - Monospace styled text
- `HeaderSection.kt` - Reusable section headers

### Phase 8: Terminal UI Theme

Replicate the retro aesthetic:

```kotlin
// Color.kt
val TerminalGreen = Color(0xFF00FF00)
val TerminalAmber = Color(0xFFFFB000)
val TerminalBackground = Color(0xFF0D1117)
val TerminalDim = Color(0xFF6E7681)

// Type.kt
val TerminalFontFamily = FontFamily(
    Font(R.font.jetbrains_mono_regular),
    Font(R.font.jetbrains_mono_bold, FontWeight.Bold)
)
```

### Phase 9: Caching

**CacheManager.kt using DataStore:**

```kotlin
@Singleton
class CacheManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val dataStore = context.dataStore

    suspend fun saveSession(session: ObservationSession)
    suspend fun loadSession(date: LocalDate, location: ObserverLocation): ObservationSession?
    suspend fun clearCache()

    private fun getCacheKey(date: LocalDate, location: ObserverLocation): String
}
```

Cache key format: `session_{date}_{lat}_{lon}` (same as iOS)

### Phase 10: Background Notifications (WorkManager)

**Optional feature:** Notify users of meteor showers and ISS passes.

**MeteorShowerNotificationWorker.kt:**
```kotlin
@HiltWorker
class MeteorShowerNotificationWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val meteorShowerService: MeteorShowerService
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val activeShower = meteorShowerService.getActiveShower()
        if (activeShower != null && activeShower.isNearPeak()) {
            showNotification(activeShower)
        }
        return Result.success()
    }

    private fun showNotification(shower: MeteorShower) {
        // Create notification with shower details
    }
}
```

**Schedule periodic checks:**
```kotlin
// In Application or ViewModel
val meteorShowerWorkRequest = PeriodicWorkRequestBuilder<MeteorShowerNotificationWorker>(
    1, TimeUnit.DAYS
).setConstraints(
    Constraints.Builder()
        .setRequiredNetworkType(NetworkType.NOT_REQUIRED) // Local calculation
        .build()
).build()

WorkManager.getInstance(context).enqueueUniquePeriodicWork(
    "meteor_shower_check",
    ExistingPeriodicWorkPolicy.KEEP,
    meteorShowerWorkRequest
)
```

**IssPassNotificationWorker.kt:**
- Similar pattern for ISS pass notifications
- Requires network connectivity
- Schedule checks based on user's location

### Phase 11: Testing

**Unit Tests:**
- `DeepSkyCalculationServiceTest.kt` - Julian date, LST, alt/az calculations
- `SunsetServiceTest.kt` - Observation window calculations
- `MeteorShowerServiceTest.kt` - Shower status logic

**Integration Tests:**
- API response parsing
- ViewModel state transitions

**UI Tests:**
- Navigation flows
- Permission handling

---

## API Reference

### NASA JPL Horizons
```
GET https://ssd.jpl.nasa.gov/api/horizons.api
Parameters:
  format=text
  COMMAND='301' (Moon), '199' (Mercury), etc.
  OBJ_DATA='NO'
  MAKE_EPHEM='YES'
  EPHEM_TYPE='OBSERVER'
  CENTER='coord@399'
  COORD_TYPE='GEODETIC'
  SITE_COORD='{lon},{lat},{elevation}'
  START_TIME='2025-01-22 18:00'
  STOP_TIME='2025-01-23 06:00'
  STEP_SIZE='1 h'
  QUANTITIES='4' (or '4,10,23' for Moon)
```

### Open-Meteo Weather
```
GET https://api.open-meteo.com/v1/forecast
Parameters:
  latitude={lat}
  longitude={lon}
  current=cloud_cover,visibility,relative_humidity_2m,wind_speed_10m
  hourly=cloud_cover_low,cloud_cover_mid,cloud_cover_high
```

### Where the ISS at API (Recommended)
```
GET https://api.wheretheiss.at/v1/satellites/25544
Response: Current ISS position (lat, lon, altitude, velocity)

GET https://api.wheretheiss.at/v1/satellites/25544/positions
Parameters:
  timestamps={unix_timestamp1,unix_timestamp2,...}
Response: Predicted positions at given times
```

### N2YO API (Alternative)
```
GET https://api.n2yo.com/rest/v1/satellite/visualpasses/{norad_id}/{lat}/{lon}/{alt}/{days}/{min_visibility}
Parameters:
  norad_id=25544 (ISS)
  lat, lon, alt = observer location
  days = prediction window (max 10)
  min_visibility = minimum seconds visible
Headers:
  apiKey: {your_api_key}
```
**Note:** Requires free API key from n2yo.com

---

## Key Differences from iOS

| Aspect | iOS | Android |
|--------|-----|---------|
| UI Framework | SwiftUI | Jetpack Compose |
| State Management | Combine + @Published | StateFlow + collectAsState |
| Async | async/await | Coroutines |
| Location | CoreLocation | Fused Location Provider |
| HTTP Client | URLSession | OkHttp + Retrofit |
| Caching | FileManager + Codable | DataStore + Kotlinx Serialization |
| Date/Time | Foundation Date | java.time (LocalDate, LocalDateTime) |
| Dependency Injection | Manual / Environment | Hilt (Dagger) |
| Background Tasks | BackgroundTasks | WorkManager |
| Navigation | NavigationStack | Navigation Compose (type-safe) |
| Network Monitoring | NWPathMonitor | ConnectivityManager |

---

## Verification

### Manual Testing Checklist
- [ ] App launches and shows default location (San Francisco)
- [ ] GPS location updates correctly
- [ ] Manual coordinates can be entered
- [ ] Date picker changes observation date
- [ ] Objects load with correct visibility status
- [ ] Pull-to-refresh fetches fresh data
- [ ] Object detail view shows all data
- [ ] Share functionality works
- [ ] Weather data displays
- [ ] Meteor shower alerts appear when active
- [ ] Terminal aesthetic matches iOS version
- [ ] Offline mode shows cached data with indicator
- [ ] App recovers gracefully when network returns
- [ ] Background notifications work (if enabled)
- [ ] Release build works with Proguard/R8 enabled

### Automated Tests
```bash
./gradlew test                    # Unit tests
./gradlew connectedAndroidTest    # Instrumented tests
```

---

## Proguard / R8 Rules

**proguard-rules.pro** - Required for release builds:

```proguard
# Kotlinx Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.skychecker.**$$serializer { *; }
-keepclassmembers class com.skychecker.** {
    *** Companion;
}
-keepclasseswithmembers class com.skychecker.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Retrofit
-keepattributes Signature, Exceptions
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Hilt
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.android.internal.managers.ComponentSupplier { *; }

# Data classes (keep for serialization)
-keep class com.skychecker.data.model.** { *; }
```

---

## Play Store Preparation

After development:

1. **App signing** - Generate upload key, configure Play App Signing
2. **Store listing** - Screenshots, description, feature graphic
3. **Privacy policy** - Required (location data)
4. **Data safety form** - Declare location usage
5. **Release track** - Start with internal testing, then closed beta
6. **Target API compliance** - Ensure API 34 target

---

## Files to Reference

iOS source files for porting logic:

- **Models:** `/Users/andrewchamberlain/github/sky-checker/SkyChecker/SkyChecker/SkyChecker/Models/`
- **ViewModel:** `/Users/andrewchamberlain/github/sky-checker/SkyChecker/SkyChecker/SkyChecker/ViewModels/SkyCheckerViewModel.swift`
- **Services:** `/Users/andrewchamberlain/github/sky-checker/SkyChecker/SkyChecker/SkyChecker/Services/`
- **Views:** `/Users/andrewchamberlain/github/sky-checker/SkyChecker/SkyChecker/SkyChecker/Views/`
