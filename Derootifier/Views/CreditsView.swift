import SwiftUI

struct CreditsView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      Form {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("RootHide Patcher").font(.title2.weight(.semibold))
            Text("Convert jailbreak tweak packages for RootHide.")
              .font(.subheadline).foregroundColor(.secondary)
          }
          .padding(.vertical, 8)
          HStack {
            Text("Version")
            Spacer()
            Text(verbatim: version).foregroundColor(.secondary)
          }
        }
        Section {
          credit("haxi0", detail: "Original app", profile: "haxi0")
          credit("evelyneee", detail: "Concept and development support", profile: "evelyneee")
          credit("NightwindDev", detail: "Testing", profile: "NightwindDev")
          credit("korboybeats", detail: "Testing", profile: "korboybeats")
        } header: {
          Text("Acknowledgments")
        }
        Section {
          Link(
            "RootHide Patcher Source",
            destination: URL(string: "https://github.com/roothide/RootHidePatcher")!)
          NavigationLink("Licenses") { LicenseListView() }
        } header: {
          Text("Open Source")
        }
      }
      .navigationTitle("About Patcher")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .navigationViewStyle(.stack)
    .tint(PatcherStyle.accent)
  }

  private var version: String {
    let info = Bundle.main.infoDictionary
    return
      "\(info?["CFBundleShortVersionString"] as? String ?? "—") (\(info?["CFBundleVersion"] as? String ?? "—"))"
  }

  private func credit(_ name: String, detail: LocalizedStringKey, profile: String) -> some View {
    Link(destination: URL(string: "https://github.com/\(profile)")!) {
      HStack(spacing: PatcherStyle.spacing) {
        VStack(alignment: .leading, spacing: 4) {
          Text(verbatim: name).foregroundColor(.primary)
          Text(detail).font(.footnote).foregroundColor(.secondary)
        }
        Spacer()
        Image(systemName: "arrow.up.right").font(.footnote).foregroundColor(.secondary)
      }
      .padding(.vertical, 4)
    }
  }
}
