import SwiftUI

struct ConversionLogView: View {
  let result: ConversionResult
  @State private var shareItem: PatcherShareItem?

  var body: some View {
    ScrollView {
      Text(verbatim: result.log.isEmpty ? String(localized: "No output was recorded.") : result.log)
        .font(.system(.footnote, design: .monospaced))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .navigationTitle("Conversion Log")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button {
            UIPasteboard.general.string = result.log
          } label: {
            Label("Copy Log", systemImage: "doc.on.doc")
          }
          Button {
            shareItem = PatcherShareItem(items: [result.log])
          } label: {
            Label("Share Log", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("Log Actions")
      }
    }
    .sheet(item: $shareItem) { item in PatcherShareSheet(items: item.items) }
  }
}
