import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var dailyTarget: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Daily Goal")) {
                    Stepper(value: $dailyTarget, in: 1...100) {
                        Text("Words per day: \(dailyTarget)")
                    }
                    Text("This target is used as a personal goal. It doesn't alter training logic, only tracks your desired daily count.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let (container, _) = makePreviewData()
        SettingsView(dailyTarget: .constant(10))
            .modelContainer(container)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
