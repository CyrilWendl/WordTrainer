import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var word: Word

    @State private var answer = ""
    @State private var feedback: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Translate to foreign:")
            Text(word.native).font(.largeTitle)
            TextField("Type the word...", text: $answer)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onSubmit(check)

            if let feedback {
                Text(feedback).font(.headline).foregroundColor(feedback == "Correct" ? .green : .red)
            }

            Button("Check") { check() }
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle(word.native)
    }

    func check() {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { feedback = "Please type an answer"; return }

        if trimmed.lowercased() == word.foreign.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            feedback = "Correct"
            word.score += 1
            word.lastCorrectAt = Date()
            try? modelContext.save()
        } else {
            feedback = "Wrong — expected: \(word.foreign)"
            word.score = max(0, word.score - 1)
            try? modelContext.save()
        }
    }
}

#if DEBUG
// Swift
#Preview {
    let (container, words) = makePreviewData()
    PracticeView(word: words[0])
        .modelContainer(container)
        .previewLayout(.sizeThatFits)
        .padding()
}
#endif
