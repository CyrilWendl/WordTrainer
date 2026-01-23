import SwiftUI
import SwiftData

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

#if DEBUG
struct AddWordView_Previews: PreviewProvider {
    static var previews: some View {
        let (container, _) = makePreviewData()
        AddWordView { _, _ in }
            .modelContainer(container)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
