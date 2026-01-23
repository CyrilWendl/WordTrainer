import Foundation
import SwiftData

// Shared preview data generator used by all view previews in DEBUG builds
#if DEBUG
func makePreviewData() -> (container: ModelContainer, words: [Word]) {
    let schema = Schema([Word.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    do {
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = container.mainContext

        let w1 = Word(native: "House", foreign: "Maison", score: 3, createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date())!)
        let w2 = Word(native: "Apple", foreign: "Pomme", score: 5, createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
        let w3 = Word(native: "Car", foreign: "Voiture", score: 1, createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!)
        let w4 = Word(native: "Book", foreign: "Livre", score: 6, createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date())!)
        let w5 = Word(native: "Water", foreign: "Eau", score: 0, createdAt: Date())
        w5.lastCorrectAt = Date()

        ctx.insert(w1)
        ctx.insert(w2)
        ctx.insert(w3)
        ctx.insert(w4)
        ctx.insert(w5)
        try? ctx.save()

        return (container, [w1, w2, w3, w4, w5])
    } catch {
        fatalError("Failed to create preview ModelContainer: \(error)")
    }
}
#endif
