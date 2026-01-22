import SwiftUI

struct WeatherDetailView: View {
    @ObservedObject var viewModel: SkyCheckerViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let weather = viewModel.weather {
                        // Location
                        if let location = viewModel.location {
                            Text("> Location: \(location.displayString)")
                                .foregroundColor(.terminalGreen)
                            Text("")
                        }

                        // Current conditions
                        Text("── Current Conditions ──")
                            .foregroundColor(.terminalDim)

                        HStack {
                            Text("Rating:")
                                .frame(width: 100, alignment: .leading)
                            Text("[\(weather.ratingStars)]")
                                .foregroundColor(weather.observationRating >= 4 ? .terminalBright : .terminalGreen)
                            Text(weather.ratingDescription)
                                .foregroundColor(.terminalDim)
                        }
                        .foregroundColor(.terminalGreen)

                        HStack {
                            Text("Clouds:")
                                .frame(width: 100, alignment: .leading)
                            Text("\(weather.cloudCover)%")
                            Text("(\(weather.cloudDescription))")
                                .foregroundColor(.terminalDim)
                        }
                        .foregroundColor(.terminalGreen)

                        HStack {
                            Text("Visibility:")
                                .frame(width: 100, alignment: .leading)
                            Text(formatVisibility(weather.visibility))
                            Text("(\(weather.visibilityDescription))")
                                .foregroundColor(.terminalDim)
                        }
                        .foregroundColor(.terminalGreen)

                        HStack {
                            Text("Humidity:")
                                .frame(width: 100, alignment: .leading)
                            Text("\(weather.humidity)%")
                            if weather.humidity > 85 {
                                Text("(dew risk)")
                                    .foregroundColor(.terminalDim)
                            }
                        }
                        .foregroundColor(.terminalGreen)

                        HStack {
                            Text("Wind:")
                                .frame(width: 100, alignment: .leading)
                            Text("\(Int(weather.windSpeed)) km/h")
                            if weather.windSpeed > 30 {
                                Text("(gusty)")
                                    .foregroundColor(.terminalDim)
                            }
                        }
                        .foregroundColor(.terminalGreen)

                        // Cloud layers
                        Text("")
                        Text("── Cloud Layers ──")
                            .foregroundColor(.terminalDim)

                        cloudLayerBar(label: "High:", value: weather.cloudCoverHigh)
                        cloudLayerBar(label: "Mid:", value: weather.cloudCoverMid)
                        cloudLayerBar(label: "Low:", value: weather.cloudCoverLow)

                        // Observation tips
                        Text("")
                        Text("── Observation Tips ──")
                            .foregroundColor(.terminalDim)

                        ForEach(observationTips(weather), id: \.self) { tip in
                            Text("* \(tip)")
                                .foregroundColor(.terminalGreen)
                        }

                        // Data attribution
                        Text("")
                        Text("── Data Source ──")
                            .foregroundColor(.terminalDim)
                        Text("Weather data from Open-Meteo.com")
                            .foregroundColor(.terminalDim)
                        Text("Updated: \(formatTime(weather.timestamp))")
                            .foregroundColor(.terminalDim)

                    } else {
                        Text("Weather data not available")
                            .foregroundColor(.terminalDim)
                        Text("")
                        Text("Pull to refresh to load weather")
                            .foregroundColor(.terminalDim)
                    }

                    Spacer()
                }
                .font(.terminalCaption)
                .padding()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("< Weather >")
                    .font(.terminalTitle)
                    .foregroundColor(.terminalGreen)
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func cloudLayerBar(label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .frame(width: 50, alignment: .leading)
            Text(cloudBar(value))
                .foregroundColor(value > 50 ? .terminalDim : .terminalBright)
            Text("\(value)%")
                .frame(width: 40, alignment: .trailing)
                .foregroundColor(.terminalDim)
        }
        .foregroundColor(.terminalGreen)
    }

    private func cloudBar(_ percent: Int) -> String {
        let filled = percent / 10
        let empty = 10 - filled
        return "[" + String(repeating: "#", count: filled) + String(repeating: "-", count: empty) + "]"
    }

    private func formatVisibility(_ meters: Double) -> String {
        if meters >= 10000 {
            return String(format: "%.0f km", meters / 1000)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func observationTips(_ weather: WeatherData) -> [String] {
        var tips: [String] = []

        // Cloud-based tips
        if weather.cloudCover < 10 {
            tips.append("Excellent clarity for deep sky objects")
        } else if weather.cloudCover < 30 {
            tips.append("Good conditions for most targets")
        } else if weather.cloudCover < 60 {
            tips.append("Stick to bright objects (planets, Moon)")
        } else {
            tips.append("Poor conditions - consider rescheduling")
        }

        // High clouds
        if weather.cloudCoverHigh > 50 && weather.cloudCoverLow < 30 {
            tips.append("High thin clouds may reduce contrast")
        }

        // Humidity warning
        if weather.humidity > 85 {
            tips.append("High humidity - watch for dew on optics")
            tips.append("Consider using a dew heater")
        } else if weather.humidity > 70 {
            tips.append("Moderate humidity - monitor for dew")
        }

        // Wind warning
        if weather.windSpeed > 40 {
            tips.append("Strong wind - use low magnification")
        } else if weather.windSpeed > 25 {
            tips.append("Breezy - may affect long exposures")
        }

        // Visibility
        if weather.visibility > 20000 {
            tips.append("Excellent transparency tonight")
        } else if weather.visibility < 10000 {
            tips.append("Reduced transparency - haze likely")
        }

        return tips
    }
}
