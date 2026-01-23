import SwiftUI

struct OptionsSheet: View {
    @Binding var isPresented: Bool
    @Binding var filter: WordFilter
    var showStats: () -> Void
    var showAbout: () -> Void
    var showSettings: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Filter")) {
                    Picker("Filter", selection: $filter) {
                        ForEach(WordFilter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button(action: {
                        // Dismiss and then invoke the action so the sheet isn't covering the destination
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showStats()
                        }
                    }) {
                        Label("Charts", systemImage: "chart.bar")
                    }

                    Button(action: {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showSettings()
                        }
                    }) {
                        Label("Settings", systemImage: "gear")
                    }

                    Button(action: {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showAbout()
                        }
                    }) {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Options")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}

#Preview {
    OptionsSheet(isPresented: .constant(true), filter: .constant(.all), showStats: {}, showAbout: {}, showSettings: {})
}
