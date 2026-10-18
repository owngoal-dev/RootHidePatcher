import SwiftUI

struct CreditsView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          VStack(spacing: 10) {
            AppMark()
            VStack(spacing: 4) {
              Text(verbatim: AppBrand.name).font(.title2.weight(.bold))
              Text("Convert tweak packages for RootHide custom firmware.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            Text("Version \(version)")
              .font(.footnote.weight(.medium).monospacedDigit())
              .foregroundColor(.secondary)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(Capsule().fill(PatcherStyle.well))
          }
          .frame(maxWidth: .infinity)
          .padding(.top, 12)
          .accessibilityElement(children: .combine)

          VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Acknowledgments")
            PatcherCard(padding: 0) {
              VStack(spacing: 0) {
                credit(
                  "roothideDev", detail: "RootHide Patcher and conversion engine",
                  url: AppBrand.upstreamURL)
                inset
                credit("haxi0", detail: "Original app")
                inset
                credit("evelyneee", detail: "Concept and development support")
                inset
                credit("NightwindDev", detail: "Testing")
                inset
                credit("korboybeats", detail: "Testing")
              }
            }
          }

          VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Open Source")
            PatcherCard(padding: 0) {
              VStack(spacing: 0) {
                Link(destination: AppBrand.sourceURL) {
                  CardRow(title: "Umbra Patcher Source")
                    .padding(.horizontal, PatcherStyle.gutter)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                inset
                NavigationLink {
                  LicenseListView()
                } label: {
                  CardRow(title: "Licenses")
                    .padding(.horizontal, PatcherStyle.gutter)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
              }
            }
          }
        }
        .padding(PatcherStyle.gutter)
        .frame(maxWidth: PatcherStyle.readableWidth)
        .frame(maxWidth: .infinity)
      }
      .background(PatcherStyle.page.ignoresSafeArea())
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

  private var inset: some View {
    Divider().padding(.leading, PatcherStyle.gutter)
  }

  private var version: String {
    let info = Bundle.main.infoDictionary
    return
      "\(info?["CFBundleShortVersionString"] as? String ?? "—") (\(info?["CFBundleVersion"] as? String ?? "—"))"
  }

  private func credit(_ name: String, detail: LocalizedStringKey, url: URL? = nil) -> some View {
    Link(destination: url ?? URL(string: "https://github.com/\(name)")!) {
      HStack(spacing: PatcherStyle.spacing) {
        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: name).foregroundColor(.primary)
          Text(detail).font(.footnote).foregroundColor(.secondary)
        }
        Spacer()
        Image(systemName: "arrow.up.right")
          .font(.footnote.weight(.semibold))
          .foregroundColor(Color(uiColor: .tertiaryLabel))
          .accessibilityHidden(true)
      }
      .padding(.horizontal, PatcherStyle.gutter)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
