import SwiftUI

// Terminal green color
extension Color {
    static let terminalGreen = Color(red: 0.2, green: 1.0, blue: 0.2)
    static let terminalDim = Color(red: 0.15, green: 0.6, blue: 0.15)
    static let terminalBright = Color(red: 0.4, green: 1.0, blue: 0.4)
}

// Monospace font - like Mac Terminal
extension Font {
    static func terminal(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
    static let terminalBody: Font = .system(size: 15, weight: .regular, design: .monospaced)
    static let terminalCaption: Font = .system(size: 15, weight: .regular, design: .monospaced)
    static let terminalSmall: Font = .system(size: 13, weight: .regular, design: .monospaced)
    static let terminalTitle: Font = .system(size: 18, weight: .medium, design: .monospaced)
}

struct ContentView: View {
    @StateObject private var viewModel = SkyCheckerViewModel()
    @State private var showingLocationSheet = false
    @State private var showingDatePicker = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if viewModel.isLoading {
                        Spacer()
                        Text("Fetching data from NASA...")
                            .font(.terminalBody)
                            .foregroundColor(.terminalGreen)
                        Text("Please wait...")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalDim)
                            .padding(.top, 8)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 2) {
                                // Table header
                                HStack {
                                    Text("Object")
                                        .frame(width: 100, alignment: .leading)
                                    Text("Status")
                                        .frame(width: 70, alignment: .center)
                                    Text("Rise")
                                        .frame(width: 60, alignment: .center)
                                    Text("Set")
                                        .frame(width: 60, alignment: .center)
                                }
                                .font(.terminalCaption)
                                .foregroundColor(.terminalDim)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                
                                ForEach(viewModel.sortedObjects) { obj in
                                    NavigationLink {
                                        ObjectDetailView(objectId: obj.id, viewModel: viewModel)
                                    } label: {
                                        ObjectRowView(object: obj)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // About link at bottom
                                Spacer()
                                    .frame(height: 30)
                                
                                Button {
                                    showingAbout = true
                                } label: {
                                    Text("[About]")
                                        .font(.terminalSmall)
                                        .foregroundColor(.terminalDim)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                Spacer()
                                    .frame(height: 40)
                            }
                        }
                        .refreshable {
                            await viewModel.refreshData()
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SkyChecker v1.0")
                        .font(.terminalTitle)
                        .foregroundColor(.terminalGreen)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingDatePicker = true } label: {
                        Text("[Date]")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingLocationSheet = true } label: {
                        Text("[Loc]")
                            .font(.terminalCaption)
                            .foregroundColor(.terminalGreen)
                    }
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingLocationSheet) {
                LocationSettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $viewModel.selectedDate) {
                    showingDatePicker = false
                    Task { await viewModel.loadData() }
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutView { showingAbout = false }
            }
            .alert("ERROR", isPresented: $viewModel.showingError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .preferredColorScheme(.dark)
        .task { await viewModel.initialize() }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let loc = viewModel.location {
                Text("> Location: \(loc.displayString)")
                    .foregroundColor(.terminalGreen)
            }
            
            Text("> Date: \(formatDate(viewModel.selectedDate))")
                .foregroundColor(.terminalGreen)
            
            HStack(spacing: 16) {
                Text("> Sunset: \(viewModel.formattedSunset)")
                Text("Sunrise: \(viewModel.formattedSunrise)")
            }
            .foregroundColor(.terminalGreen)
            
            Text("> \(viewModel.visibleCount) objects visible tonight")
                .foregroundColor(.terminalBright)
        }
        .font(.terminalCaption)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .padding(.bottom, 24)
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
