import SwiftUI
import Charts
import SwiftData

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

#if DEBUG
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        let (container, words) = makePreviewData()
        StatsView(words: words)
            .modelContainer(container)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
