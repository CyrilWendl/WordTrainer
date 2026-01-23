//
//  ContentView.swift
//  WordTrainer
//
//  Created by Cyril Wendl on 23.01.2026.
//

import SwiftUI
import Charts

enum WordFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case toPractice = "To Practice"
    case mastered = "Mastered"

    var id: String { rawValue }
}

struct ContentView: View {
    // Simple in-memory store backed by a JSON file
    @State private var words: [Word] = []

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showingAdd = false
    @State private var showingPractice: Word? = nil
    @State private var showingStats = false
    @State private var showingAbout = false
    @State private var editingWord: Word? = nil

    // Persist selected filter across launches
    @AppStorage("wordFilter") private var storedFilterRaw: String = WordFilter.all.rawValue
    @State private var filter: WordFilter = .all

    // Delete confirmation state
    @State private var showingDeleteConfirmation = false
    @State private var pendingDeleteWords: [Word] = []

    // Computed filtered words according to the selected filter
    private var filteredWords: [Word] {
        switch filter {
        case .all: return words
        case .toPractice: return words.filter { !$0.mastered }
        case .mastered: return words.filter { $0.mastered }
        }
    }

    // File URL for persistence
    private var storageURL: URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("words.json")
    }

    var body: some View {
        NavigationSplitView {
            List {
                // Dynamic section title based on filter
                let sectionTitle = (filter == .all) ? "All Words" : filter.rawValue

                Section(header: Text(sectionTitle)) {
                    ForEach(filteredWords) { word in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                Text(word.native).font(.headline)
                                Text(word.foreign).font(.subheadline).foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                // Score
                                Text("⭐️ \(word.score)")
                                    .font(.subheadline)

                                // Mastered badge
                                if word.mastered {
                                    Label("Mastered", systemImage: "checkmark.seal.fill")
                                        .font(.caption2)
                                        .padding(6)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                } else {
                                    Label("To practice", systemImage: "clock")
                                        .font(.caption2)
                                        .padding(6)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { showingPractice = word }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button { showingPractice = word } label: {
                                Label("Practice", systemImage: "brain.head.profile")
                            }
                            .tint(.blue)

                            Button { editingWord = word } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.green)

                            // Use confirmation flow for deletes
                            Button(role: .destructive) {
                                pendingDeleteWords = [word]
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }

                // Keep summary sections for quick overview when "All" is selected
                if filter == .all {
                    Section(header: Text("Mastered")) {
                        ForEach(words.filter { $0.mastered }) { word in
                            HStack { Text(word.native); Spacer(); Text("\(word.score)") }
                        }
                    }

                    Section(header: Text("To Learn")) {
                        ForEach(words.filter { !$0.mastered }) { word in
                            HStack { Text(word.native); Spacer(); Text("\(word.score)") }
                        }
                    }
                }
            }
            .navigationTitle("Word Trainer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }

                // Menu for filter, charts and about
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filter", selection: $filter) {
                            ForEach(WordFilter.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }

                        Divider()

                        Button { showingStats = true } label: {
                            Label("Charts", systemImage: "chart.bar")
                        }

                        Button { showingAbout = true } label: {
                            Label("About", systemImage: "info.circle")
                        }
                    } label: {
                        Label("Options", systemImage: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { if let random = filteredWords.randomElement() { showingPractice = random } } label: {
                        Label("Practice Random", systemImage: "shuffle")
                    }
                }
            }
            // Delete confirmation alert
            .alert("Delete Word", isPresented: $showingDeleteConfirmation, actions: {
                Button("Delete", role: .destructive) { performConfirmedDeletion() }
                Button("Cancel", role: .cancel) { pendingDeleteWords = [] }
            }, message: {
                if pendingDeleteWords.count == 1 {
                    Text("Are you sure you want to delete ‘\(pendingDeleteWords.first?.native ?? "this word")’? This cannot be undone.")
                } else {
                    Text("Are you sure you want to delete \(pendingDeleteWords.count) words? This cannot be undone.")
                }
            })
            // Keep toolbar and list modifiers above
        } detail: {
            if let practice = showingPractice {
                PracticeView(word: practice) { updated in
                    if let idx = words.firstIndex(where: { $0.id == updated.id }) { words[idx] = updated; saveWords() }
                }
            } else {
                Text("Select a word to practice")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // sync persisted filter
            filter = WordFilter(rawValue: storedFilterRaw) ?? .all
            loadWords()
        }
        .onChange(of: filter) { new in
            storedFilterRaw = new.rawValue
        }
        .sheet(isPresented: $showingAdd) {
            AddWordView { native, foreign in
                if !native.isEmpty && !foreign.isEmpty { addWord(native: native, foreign: foreign) }
                showingAdd = false
            }
            .presentationDetents([.medium, .large])
        }
        // On compact devices (iPhone) present the practice screen modally
        .sheet(isPresented: Binding(get: { showingPractice != nil && horizontalSizeClass == .compact }, set: { if !$0 { showingPractice = nil } })) {
            if let practice = showingPractice {
                PracticeView(word: practice) { updated in
                    if let idx = words.firstIndex(where: { $0.id == updated.id }) { words[idx] = updated; saveWords() }
                    showingPractice = nil
                }
            }
        }
        // Edit sheet
        .sheet(item: $editingWord) { word in
            EditWordView(word: word) { updated in
                if let idx = words.firstIndex(where: { $0.id == updated.id }) { words[idx] = updated; saveWords() }
            }
            .presentationDetents([.medium, .large])
        }
        // Stats sheet
        .sheet(isPresented: $showingStats) {
            NavigationStack { StatsView(words: words) }
        }
        // About sheet
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }

    // MARK: - Persistence
    private func loadWords() {
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([Word].self, from: data)
            words = decoded
        } catch {
            // If file doesn't exist or decode fails, start with sample data
            if words.isEmpty {
                words = sampleWords()
            }
        }
    }

    private func saveWords() {
        do {
            let data = try JSONEncoder().encode(words)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("Failed to save words: \(error)")
        }
    }

    // MARK: - Actions
    private func addWord(native: String, foreign: String) {
        withAnimation {
            let w = Word(native: native, foreign: foreign)
            words.insert(w, at: 0)
            saveWords()
        }
    }

    private func delete(offsets: IndexSet) {
        // Map offsets from filteredWords into real Word instances and ask for confirmation
        let wordsToDelete = offsets.compactMap { idx -> Word? in
            guard idx >= 0 && idx < filteredWords.count else { return nil }
            return filteredWords[idx]
        }
        if !wordsToDelete.isEmpty {
            pendingDeleteWords = wordsToDelete
            showingDeleteConfirmation = true
        }
    }

    private func performConfirmedDeletion() {
        withAnimation {
            let ids = Set(pendingDeleteWords.map { $0.id })
            words.removeAll(where: { ids.contains($0.id) })
            saveWords()
            pendingDeleteWords = []
            showingDeleteConfirmation = false
        }
    }

    // Sample data for first run / previews
    private func sampleWords() -> [Word] {
        return [
            Word(native: "House", foreign: "Maison", score: 3, createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date())!),
            Word(native: "Apple", foreign: "Pomme", score: 5, createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date())!),
            Word(native: "Car", foreign: "Voiture", score: 1, createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!),
            Word(native: "Book", foreign: "Livre", score: 6, createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date())!),
            Word(native: "Water", foreign: "Eau", score: 0, createdAt: Date())
        ]
    }
}

// MARK: - AddWordView
struct AddWordView: View {
    @State private var native = ""
    @State private var foreign = ""
    var onSave: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Native (e.g. English)", text: $native)
                TextField("Foreign (e.g. Spanish)", text: $foreign)
            }
            .navigationTitle("Add Word")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(native.trimmingCharacters(in: .whitespaces), foreign.trimmingCharacters(in: .whitespaces)) }
                        .disabled(native.trimmingCharacters(in: .whitespaces).isEmpty || foreign.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSave("", "") }
                }
            }
        }
    }
}

// MARK: - EditWordView (uses onSave callback)
struct EditWordView: View {
    @Environment(\.dismiss) private var dismiss

    var word: Word
    var onSave: (Word) -> Void

    @State private var native: String
    @State private var foreign: String
    @State private var scoreString: String
    @State private var mastered: Bool

    init(word: Word, onSave: @escaping (Word) -> Void) {
        self.word = word
        self.onSave = onSave
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
                HStack {
                    TextField("Score", text: $scoreString)
                        .keyboardType(.numberPad)
                    Stepper("", value: Binding(get: {
                        Int(scoreString) ?? word.score
                    }, set: { new in
                        scoreString = String(new)
                    }), in: 0...999)
                    .labelsHidden()
                }
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
        var updated = word
        updated.native = native.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.foreign = foreign.trimmingCharacters(in: .whitespacesAndNewlines)
        if let s = Int(scoreString) { updated.score = max(0, s) }
        updated.mastered = mastered
        updated.lastCorrectAt = updated.lastCorrectAt
        onSave(updated)
    }
}

// MARK: - PracticeView (uses onUpdate callback)
struct PracticeView: View {
    var word: Word
    var onUpdate: (Word) -> Void

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
        var updated = word
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { feedback = "Please type an answer"; return }

        if trimmed.lowercased() == word.foreign.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            feedback = "Correct"
            updated.score += 1
            updated.lastCorrectAt = Date()
            onUpdate(updated)
        } else {
            feedback = "Wrong — expected: \(word.foreign)"
            updated.score = max(0, updated.score - 1)
            onUpdate(updated)
        }
    }
}

// MARK: - StatsView
struct StatsView: View {
    var words: [Word]

    // Aggregate counts per month (using createdAt if lastCorrectAt is nil)
    private var learnedPerMonth: [String: Int] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let entries = words.map { word -> String in
            let date = word.lastCorrectAt ?? word.createdAt
            return formatter.string(from: date)
        }
        return Dictionary(grouping: entries, by: { $0 }).mapValues { $0.count }
    }

    // helper array sorted by month string
    private var learnedPerMonthArray: [(month: String, count: Int)] {
        learnedPerMonth.keys.sorted().map { ($0, learnedPerMonth[$0] ?? 0) }
    }

    private var masteredCount: Int { words.filter { $0.mastered }.count }
    private var toLearnCount: Int { words.count - masteredCount }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Summary").font(.title2).padding(.horizontal)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total words"); Text("\(words.count)").font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Mastered"); Text("\(masteredCount)").font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("To learn"); Text("\(toLearnCount)").font(.headline)
                    }
                }
                .padding(.horizontal)

                // Bar chart: Learned per month
                if !learnedPerMonthArray.isEmpty {
                    Text("Learned per month").font(.headline).padding(.horizontal)
                    Chart {
                        ForEach(learnedPerMonthArray, id: \.month) { entry in
                            BarMark(
                                x: .value("Month", entry.month),
                                y: .value("Count", entry.count)
                            )
                        }
                    }
                    .chartYAxisLabel("Words")
                    .frame(height: 240)
                    .padding(.horizontal)
                }

                // Donut chart: mastered vs to learn
                Text("Progress").font(.headline).padding(.horizontal)
                Chart {
                    let progress = [("Mastered", masteredCount), ("To Learn", toLearnCount)]
                    ForEach(Array(progress.enumerated()), id: \.element.0) { _, element in
                        let (label, count) = element
                        SectorMark(
                            angle: .value("Count", count),
                            innerRadius: .ratio(0.5),
                            outerRadius: .ratio(0.9)
                        )
                        .foregroundStyle(label == "Mastered" ? .green : .blue)
                        .annotation(position: .overlay) {
                            Text(label).font(.caption)
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Stats")
    }
}

// MARK: - AboutView
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Word Trainer").font(.title)
                Text("Version 1.0")
                Text("\nA simple app to practice foreign words.\n\nCreated by Cyril Wendl.")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - Preview & Dummy Data
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
