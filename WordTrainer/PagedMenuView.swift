import SwiftUI

struct PagedMenuView: View {
    @Binding var isPresented: Bool
    @Binding var filter: WordFilter
    @Binding var dailyTarget: Int
    var words: [Word]

    @State private var selection: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $selection) {
                    OptionsPage(filter: $filter)
                        .tag(0)
                    StatsPage(words: words)
                        .tag(1)
                    SettingsPage(dailyTarget: $dailyTarget)
                        .tag(2)
                    AboutPage()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .edgesIgnoringSafeArea(.all)

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                        .padding(12)
                }
                .accessibilityLabel("Close")
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
        }
    }
}

// Minimal page wrappers so we don't pull the original sheet types into this file directly.
private struct OptionsPage: View {
    @Binding var filter: WordFilter

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
            }
            .navigationTitle("Options")
        }
    }
}

private struct StatsPage: View {
    var words: [Word]
    var body: some View { NavigationStack { StatsView(words: words) } }
}

private struct SettingsPage: View {
    @Binding var dailyTarget: Int
    var body: some View { NavigationStack { SettingsView(dailyTarget: $dailyTarget) } }
}

private struct AboutPage: View {
    var body: some View { NavigationStack { AboutView() } }
}
