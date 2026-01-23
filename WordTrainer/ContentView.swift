//
//  ContentView.swift
//  WordTrainer
//
//  Created by Cyril Wendl on 23.01.2026.
//

import SwiftUI
import SwiftData
import Charts

enum WordFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case toPractice = "To Practice"
    case mastered = "Mastered"

    var id: String { rawValue }
}

// Lightweight row view extracted from the complex List row to help the compiler
private struct WordRow: View {
    let word: Word
    let onPractice: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(word.native).font(.headline)
                Text(word.foreign)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("⭐️ \(word.score)")
                    .font(.subheadline)

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
        .onTapGesture(perform: onPractice)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onPractice) {
                Label("Practice", systemImage: "brain.head.profile")
            }
            .tint(.blue)

            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.green)

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: [SortDescriptor(\Word.createdAt, order: .reverse)]) private var words: [Word]
    
    @State private var showingAdd = false
    @State private var showingPractice: Word? = nil
    @State private var showingStats = false
    @State private var showingAbout = false
    @State private var editingWord: Word? = nil
    @State private var showingSettings = false
    // Control NavigationSplitView column visibility so we can programmatically open/close the primary column
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    // Show options as a sheet (works reliably in Canvas)
    @State private var showingOptionsSheet = false
    
    // User-configurable daily target (persisted)
    @AppStorage("dailyTarget") private var dailyTarget: Int = 10
    
    // Persist selected filter across launches
    @AppStorage("wordFilter") private var storedFilterRaw: String = WordFilter.all.rawValue
    @State private var filter: WordFilter = .all
    
    // Delete confirmation state
    @State private var showingDeleteConfirmation = false
    @State private var pendingDeleteWords: [Word] = []
    
    // Computed overall mastered count used for progress bar
    private var masteredCount: Int { words.filter { $0.mastered }.count }
    
    // Computed count of words learned today (mastered and lastCorrectAt is today)
    private var dailyLearnedCount: Int {
        let calendar = Calendar.current
        return words.filter { word in
            guard let last = word.lastCorrectAt else { return false }
            return word.mastered && calendar.isDateInToday(last)
        }.count
    }
    
    // Computed filtered words according to the selected filter
    private var filteredWords: [Word] {
        switch filter {
        case .all: return words
        case .toPractice: return words.filter { !$0.mastered }
        case .mastered: return words.filter { $0.mastered }
        }
    }
    
    // Reduce complexity in DEBUG so previews compile fast. Replace with a simple stub.
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                List {
                    // Dynamic section title based on filter
                    let sectionTitle = (filter == .all) ? "All Words" : filter.rawValue
                    
                    Section(header: Text(sectionTitle)) {
                        ForEach(filteredWords) { word in
                            WordRow(
                                word: word,
                                onPractice: { showingPractice = word },
                                onEdit: { editingWord = word },
                                onDelete: {
                                    pendingDeleteWords = [word]
                                    showingDeleteConfirmation = true
                                }
                            )
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
            } detail: {
                // Place detail content in a ZStack so gestures still work; the Options button will be moved to an overlay on the split view
                ZStack {
                    Group {
                        if let practice = showingPractice {
                            PracticeView(word: practice)
                        } else {
                            Text("Select a word to practice")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    // Use simultaneousGesture so overlay button taps are delivered in Canvas/Simulator
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                // Swipe right to reveal primary column, swipe left to hide
                                let horizontal = value.translation.width
                                let vertical = value.translation.height
                                if horizontal > 80 && abs(vertical) < 60 {
                                    columnVisibility = .all
                                } else if horizontal < -80 && abs(vertical) < 60 {
                                    columnVisibility = .detailOnly
                                }
                            }
                    )
                }
            }
            // Small overlay Options button placed on the split view so it's visible above nav chrome
            .overlay(alignment: .topLeading) {
                Button(action: { showingOptionsSheet = true }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding([.top, .leading], 12)
                .contentShape(Rectangle())
                .padding(6)
                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                .accessibilityLabel("Options")
                .zIndex(100)
                .allowsHitTesting(true)
            }
            // Floating Add button in bottom-right for quick access
            .overlay(alignment: .bottomTrailing) {
                Button(action: { showingAdd = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .padding([.bottom, .trailing], 16)
                .accessibilityLabel("Add Word")
                .zIndex(200)
            }
            .navigationTitle("Word Trainer")
            // Present Options sheet from the outer container so it works regardless of split visibility
            .sheet(isPresented: $showingOptionsSheet) {
                OptionsSheet(isPresented: $showingOptionsSheet, filter: $filter, showStats: { showingStats = true }, showAbout: { showingAbout = true }, showSettings: { showingSettings = true })
            }
             .toolbar {
                 // Minimal toolbar: Add (+) and Practice Random (shuffle)
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button { showingAdd = true } label: { Image(systemName: "plus") }
                 }
                 
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button {
                         if let random = filteredWords.randomElement() {
                             showingPractice = random
                         }
                     } label: {
                         Image(systemName: "shuffle")
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
            
            // small progress bar fixed below the split view: overall mastered % and today's progress toward the daily target
            Divider()
            HStack(spacing: 12) {
                // Overall mastered percentage
                Text("Learned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                let total = max(1, Double(words.count))
                ProgressView(value: Double(masteredCount), total: total)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(height: 8)
                
                // percentage label
                Text(String(format: "%d%%", Int((Double(masteredCount) / total) * 100.0)))
                    .font(.caption2).foregroundColor(.secondary)
                
                Spacer()
                
                // Today's progress: a compact bar and numeric "Today: X / target"
                VStack(alignment: .trailing, spacing: 4) {
                    ProgressView(value: Double(dailyLearnedCount), total: Double(max(1, dailyTarget)))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 110, height: 6)
                    
                    Text("Today: \(dailyLearnedCount)/\(dailyTarget)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .onAppear {
                // sync persisted filter
                filter = WordFilter(rawValue: storedFilterRaw) ?? .all
            }
            .onChange(of: filter) {
                storedFilterRaw = filter.rawValue
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
                    PracticeView(word: practice)
                }
            }
            // Edit sheet
            .sheet(item: $editingWord) { word in
                EditWordView(word: word)
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
            // Settings sheet
            .sheet(isPresented: $showingSettings) {
                SettingsView(dailyTarget: $dailyTarget)
            }
        }
    }
    
    private func addWord(native: String, foreign: String) {
        withAnimation {
            let w = Word(native: native, foreign: foreign)
            modelContext.insert(w)
            try? modelContext.save()
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
            for w in pendingDeleteWords {
                modelContext.delete(w)
            }
            try? modelContext.save()
            pendingDeleteWords = []
            showingDeleteConfirmation = false
        }
    }
}

#Preview {
    let (container, words) = makePreviewData()
    ContentView()
        .modelContainer(container)
}
