import SwiftUI

/// The build copies the source notices, so the displayed text cannot drift from them.
struct LicenseListView: View {
  private var notices: [URL] {
    (Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "Licenses") ?? [])
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  var body: some View {
    List(notices, id: \.self) { url in
      NavigationLink {
        ScrollView {
          Text(verbatim: (try? String(contentsOf: url, encoding: .utf8)) ?? "")
            .font(.system(.footnote, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(url.deletingPathExtension().lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text(verbatim: url.deletingPathExtension().lastPathComponent)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Licenses")
    .navigationBarTitleDisplayMode(.inline)
  }
}
