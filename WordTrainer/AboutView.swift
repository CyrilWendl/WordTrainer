import SwiftUI
import SwiftData

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

#if DEBUG
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        let (container, _) = makePreviewData()
        AboutView()
            .modelContainer(container)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
