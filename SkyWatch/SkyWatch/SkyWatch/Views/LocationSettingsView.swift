import SwiftUI

struct LocationSettingsView: View {
    @ObservedObject var viewModel: SkyCheckerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingManualEntry = false
    @State private var cacheSize = CacheService.shared.formattedCacheSize()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("── Current Location ──")
                            .foregroundColor(.terminalDim)
                        
                        if let loc = viewModel.location {
                            Text("Name: \(loc.name ?? "Custom")")
                                .foregroundColor(.terminalGreen)
                            Text("Lat:  \(String(format: "%.4f", loc.latitude))°")
                                .foregroundColor(.terminalGreen)
                            Text("Lon:  \(String(format: "%.4f", loc.longitude))°")
                                .foregroundColor(.terminalGreen)
                            Text("Mode: \(viewModel.isUsingManualLocation ? "Manual" : "GPS")")
                                .foregroundColor(.terminalGreen)
                        }
                        
                        Text("")
                        Text("── Options ──")
                            .foregroundColor(.terminalDim)
                        
                        Button {
                            print("🛰️ GPS button tapped")
                            Task {
                                await viewModel.useGPSLocation()
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Text(viewModel.isUsingManualLocation ? "[ ]" : "[X]")
                                Text("Use GPS Location")
                            }
                            .foregroundColor(.terminalGreen)
                        }
                        .padding(.vertical, 4)
                        
                        Button {
                            withAnimation { showingManualEntry.toggle() }
                        } label: {
                            HStack {
                                Text(showingManualEntry ? "[v]" : "[>]")
                                Text("Enter Coordinates")
                            }
                            .foregroundColor(.terminalGreen)
                        }
                        .padding(.vertical, 4)
                        
                        if showingManualEntry {
                            Text("Latitude:")
                                .foregroundColor(.terminalDim)
                            TextField("", text: $viewModel.manualLatitude)
                                .font(.terminalBody)
                                .foregroundColor(.terminalBright)
                                .keyboardType(.numbersAndPunctuation)
                                .padding(8)
                                .background(Color.terminalGreen.opacity(0.1))
                                .overlay(Rectangle().stroke(Color.terminalDim, lineWidth: 1))
                            
                            Text("Longitude:")
                                .foregroundColor(.terminalDim)
                            TextField("", text: $viewModel.manualLongitude)
                                .font(.terminalBody)
                                .foregroundColor(.terminalBright)
                                .keyboardType(.numbersAndPunctuation)
                                .padding(8)
                                .background(Color.terminalGreen.opacity(0.1))
                                .overlay(Rectangle().stroke(Color.terminalDim, lineWidth: 1))
                            
                            Button {
                                viewModel.setManualLocation()
                                dismiss()
                            } label: {
                                Text("[ Apply ]")
                                    .foregroundColor(.terminalBright)
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Color.terminalGreen.opacity(0.2))
                                    .overlay(Rectangle().stroke(Color.terminalGreen, lineWidth: 1))
                            }
                            .padding(.top, 8)
                        }
                        
                        Text("")
                        Text("── Cache ──")
                            .foregroundColor(.terminalDim)
                        
                        Text("Size: \(cacheSize)")
                            .foregroundColor(.terminalGreen)
                        
                        Button {
                            CacheService.shared.clearAllCache()
                            cacheSize = CacheService.shared.formattedCacheSize()
                        } label: {
                            Text("[ Clear Cache ]")
                                .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                        }
                        .padding(.vertical, 4)
                        
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
                    Text("Location")
                        .font(.terminalTitle)
                        .foregroundColor(.terminalGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Text("[Done]")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalGreen)
                    }
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}
