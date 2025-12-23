import SwiftUI

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onDismiss: () -> Void
    @State private var tempDate: Date
    
    init(selectedDate: Binding<Date>, onDismiss: @escaping () -> Void) {
        self._selectedDate = selectedDate
        self.onDismiss = onDismiss
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("── Quick Select ──")
                        .foregroundColor(.terminalDim)
                    
                    HStack(spacing: 16) {
                        quickButton("Tonight", Date())
                        quickButton("Tomorrow", Date().addingTimeInterval(86400))
                        quickButton("+2 Days", Date().addingTimeInterval(172800))
                    }
                    
                    Text("")
                    Text("── Calendar ──")
                        .foregroundColor(.terminalDim)
                    
                    DatePicker("", selection: $tempDate, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(.terminalGreen)
                        .colorScheme(.dark)
                        .accentColor(.terminalGreen)
                        .environment(\.calendar, Calendar.current)
                        .background(Color.black)
                        .font(.terminalCaption)

                    Text("Selected: \(formatDateFull(tempDate))")
                        .foregroundColor(.terminalBright)

                    Button {
                        selectedDate = tempDate
                        onDismiss()
                    } label: {
                        Text("[ View Sky ]")
                            .foregroundColor(.terminalBright)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .overlay(Rectangle().stroke(Color.terminalGreen, lineWidth: 1))
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .font(.terminalCaption)
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select Date")
                        .font(.terminalTitle)
                        .foregroundColor(.terminalGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { onDismiss() } label: {
                        Text("[Cancel]")
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
    
    private func quickButton(_ title: String, _ date: Date) -> some View {
        Button {
            tempDate = Calendar.current.startOfDay(for: date)
        } label: {
            let isSelected = Calendar.current.isDate(tempDate, inSameDayAs: date)
            Text(isSelected ? "[X] \(title)" : "[ ] \(title)")
                .foregroundColor(isSelected ? .terminalBright : .terminalGreen)
        }
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd (EEEE)"
        return f.string(from: date)
    }
}
