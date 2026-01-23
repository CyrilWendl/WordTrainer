import SwiftUI
import SwiftData

struct EditWordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var word: Word

    @State private var native: String
    @State private var foreign: String
    @State private var scoreString: String
    @State private var mastered: Bool

    init(word: Word) {
        self.word = word
        _native = State(initialValue: word.native)
        _foreign = State(initialValue: word.foreign)
        _scoreString = State(initialValue: String(word.score))
        _mastered = State(initialValue: word.mastered)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Native", text: $native)
                TextField("Foreign", text: $foreign)
                TextField("Score", text: $scoreString)
                    .keyboardType(.numberPad)
                Toggle("Mastered", isOn: $mastered)
            }
            .navigationTitle("Edit Word")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        applyChanges()
                        dismiss()
                    }
                    .disabled(native.trimmingCharacters(in: .whitespaces).isEmpty || foreign.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func applyChanges() {
        word.native = native.trimmingCharacters(in: .whitespacesAndNewlines)
        word.foreign = foreign.trimmingCharacters(in: .whitespacesAndNewlines)
        if let s = Int(scoreString) { word.score = max(0, s) }
        word.mastered = mastered
        try? modelContext.save()
    }
}

#if DEBUG
struct EditWordView_Previews: PreviewProvider {
    static var previews: some View {
        let (container, words) = makePreviewData()
        EditWordView(word: words[0])
            .modelContainer(container)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
