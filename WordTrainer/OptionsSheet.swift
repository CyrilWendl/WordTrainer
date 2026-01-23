import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct OptionsSheet: View {
    @Binding var isPresented: Bool
    @Binding var filter: WordFilter
    var showStats: () -> Void
    var showAbout: () -> Void
    var showSettings: () -> Void

    // Access model context so we can insert imported words
    @Environment(\.modelContext) private var modelContext

    // File importer state
    @State private var showingImporter: Bool = false
    @State private var importErrorMessage: String? = nil
    @State private var importSuccessCount: Int? = nil

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
                    Button(action: { showingImporter = true }) {
                        Label("Import CSV", systemImage: "square.and.arrow.down.on.square")
                    }

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
            // File importer attached to the NavigationStack
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        let data = try Data(contentsOf: url)
                        let pairs = CSVImporter.parseCSV(data)
                        if pairs.isEmpty {
                            importErrorMessage = "No valid rows found in the selected file. Expecting two columns: native, foreign."
                            return
                        }

                        var inserted = 0
                        for (native, foreign) in pairs {
                            let w = Word(native: native, foreign: foreign)
                            modelContext.insert(w)
                            inserted += 1
                        }
                        try modelContext.save()
                        importSuccessCount = inserted
                    } catch {
                        importErrorMessage = error.localizedDescription
                    }
                case .failure(let err):
                    importErrorMessage = err.localizedDescription
                }
            }
            // Alerts for importer results
            .alert(item: Binding(get: {
                if importErrorMessage != nil { return AlertMessage(message: importErrorMessage!) }
                if importSuccessCount != nil { return AlertMessage(message: "Imported \(importSuccessCount!) words") }
                return nil
            }, set: { _ in
                importErrorMessage = nil
                importSuccessCount = nil
            })) { alert in
                Alert(title: Text("Import"), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
    }
}

// Helper wrapper so we can use an identifiable alert with a single string
private struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    OptionsSheet(isPresented: .constant(true), filter: .constant(.all), showStats: {}, showAbout: {}, showSettings: {})
}
