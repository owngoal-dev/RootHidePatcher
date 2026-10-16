import SwiftUI

struct ConversionLogView: View {
  let result: ConversionResult
  @State private var shareItem: PatcherShareItem?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        PatcherCard {
          VStack(alignment: .leading, spacing: 3) {
            Label {
              Text(result.succeeded ? "Conversion Complete" : "Conversion Failed")
            } icon: {
              Image(systemName: result.succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundColor(result.succeeded ? PatcherStyle.success : PatcherStyle.failure)
            }
            .font(.headline)
            Text("Exit code: \(result.exitCode)")
              .font(.system(.footnote, design: .monospaced)).foregroundColor(.secondary)
          }
          .accessibilityElement(children: .combine)
        }
        PatcherCard {
          Text(
            verbatim: result.log.isEmpty ? String(localized: "No output was recorded.") : result.log
          )
          .font(.system(.footnote, design: .monospaced))
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(PatcherStyle.gutter)
      .frame(maxWidth: 900)
      .frame(maxWidth: .infinity)
    }
    .background(PatcherStyle.page.ignoresSafeArea())
    .navigationTitle("Conversion Log")
    .navigationBarTitleDisplayMode(.inline)
    // The main screen hides the bar; this page needs it back for its title and menu.
    .navigationBarHidden(false)
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
    .sheet(item: $shareItem) { item in PatcherShareSheet(items: item.items) { shareItem = nil } }
  }
}
