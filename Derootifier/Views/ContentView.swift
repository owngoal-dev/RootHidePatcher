import SwiftUI

struct ContentView: View {
  @ObservedObject var session: ConversionSession
  @State private var showingPicker = false
  @State private var showingAbout = false
  @State private var shareItem: PatcherShareItem?
  @State private var pendingImport: URL?

  var body: some View {
    NavigationView {
      ScrollViewReader { proxy in
        Form {
          packageSection
          modeSection
          conversionSection
          if let result = session.result { resultSection(result) }
        }
        .frame(maxWidth: PatcherStyle.readableWidth)
        .frame(maxWidth: .infinity)
        .background(PatcherStyle.background.ignoresSafeArea())
        .onChange(of: session.result?.exitCode) { code in
          if code != nil { proxy.scrollTo("conversion-result", anchor: .top) }
        }
        .navigationTitle("Patcher")
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              showingAbout = true
            } label: {
              Image(systemName: "info.circle")
            }
            .accessibilityLabel("About Patcher")
          }
        }
      }
    }
    .navigationViewStyle(.stack)
    .tint(PatcherStyle.accent)
    .sheet(isPresented: $showingPicker, onDismiss: importPendingFile) {
      DocumentPicker { url in
        pendingImport = url
        showingPicker = false
      }
    }
    .sheet(isPresented: $showingAbout, onDismiss: importPendingFile) { CreditsView() }
    .sheet(item: $shareItem, onDismiss: importPendingFile) { item in
      PatcherShareSheet(items: item.items)
    }
    .alert(item: $session.issue) { issue in
      Alert(
        title: Text(issue.title), message: Text(issue.message), dismissButton: .default(Text("OK")))
    }
    .onOpenURL { url in
      if showingPicker || showingAbout || shareItem != nil {
        pendingImport = url
        showingPicker = false
        showingAbout = false
        shareItem = nil
      } else {
        session.importFile(url)
      }
    }
  }

  private func importPendingFile() {
    guard let url = pendingImport else { return }
    pendingImport = nil
    session.importFile(url)
  }

  private var packageSection: some View {
    Section {
      HStack(alignment: .top, spacing: PatcherStyle.spacing) {
        Image(systemName: "shippingbox")
          .font(.title2)
          .foregroundColor(PatcherStyle.accent)
          .frame(minWidth: 32, minHeight: 32)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
          if let file = session.selectedFile {
            Text(verbatim: file.lastPathComponent)
              .font(.headline)
              .fixedSize(horizontal: false, vertical: true)
            if let size = session.fileSize {
              Text(verbatim: size).font(.subheadline).foregroundColor(.secondary)
            }
          } else {
            Text("Choose a package").font(.headline)
            Text("Convert a jailbreak tweak for RootHide.")
              .font(.subheadline).foregroundColor(.secondary)
          }
        }
      }
      .padding(.vertical, 8)
      Button {
        UISelectionFeedbackGenerator().selectionChanged()
        showingPicker = true
      } label: {
        Label(
          session.selectedFile == nil ? "Select .deb File" : "Choose Another File",
          systemImage: "folder")
      }
      .disabled(session.isConverting)
    } header: {
      Text("Package")
    } footer: {
      Text("You can also open a .deb file in Patcher from another app.")
    }
  }

  private var modeSection: some View {
    Section {
      ForEach(ConversionMode.allCases) { mode in
        Button {
          session.mode = mode
          UISelectionFeedbackGenerator().selectionChanged()
        } label: {
          HStack(alignment: .top, spacing: PatcherStyle.spacing) {
            VStack(alignment: .leading, spacing: 4) {
              Text(mode.title).font(.body).foregroundColor(.primary)
              Text(mode.detail)
                .font(.footnote).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Image(systemName: session.mode == mode ? "checkmark.circle.fill" : "circle")
              .font(.title3)
              .foregroundColor(session.mode == mode ? PatcherStyle.accent : PatcherStyle.unselected)
              .accessibilityHidden(true)
          }
          .padding(.vertical, 4)
          .contentShape(Rectangle())
        }
        .accessibilityAddTraits(session.mode == mode ? .isSelected : [])
        .disabled(session.isConverting)
      }
    } header: {
      Text("Conversion Method")
    } footer: {
      Text(
        "Compatibility depends on the package. Conversion does not guarantee that a tweak will work."
      )
    }
  }

  private var conversionSection: some View {
    Section {
      if session.isConverting {
        HStack(spacing: PatcherStyle.spacing) {
          ProgressView()
          VStack(alignment: .leading, spacing: 4) {
            Text("Converting…").font(.headline)
            Text("Keep Patcher open until the conversion finishes.")
              .font(.footnote).foregroundColor(.secondary)
          }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
      } else {
        Button(action: session.convert) {
          Text(session.result?.succeeded == false ? "Retry Conversion" : "Convert Package")
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .disabled(session.selectedFile == nil)
      }
    }
  }

  private func resultSection(_ result: ConversionResult) -> some View {
    Section {
      HStack(alignment: .top, spacing: PatcherStyle.spacing) {
        Image(
          systemName: result.succeeded ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
        )
        .font(.title2)
        .foregroundColor(result.succeeded ? PatcherStyle.success : PatcherStyle.failure)
        .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
          Text(result.succeeded ? "Conversion Complete" : "Conversion Failed")
            .font(.headline)
          if result.succeeded {
            Text(verbatim: result.output.lastPathComponent)
              .font(.footnote).foregroundColor(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          } else {
            Text("Exit code: \(result.exitCode)")
              .font(.footnote).foregroundColor(.secondary)
            Text("Review the log before trying again.")
              .font(.footnote).foregroundColor(.secondary)
          }
        }
      }
      .padding(.vertical, 8)
      .id("conversion-result")
      if result.succeeded {
        ForEach(session.availableManagers, id: \.identifier) { manager in
          Button {
            session.openResult(in: manager)
          } label: {
            Label(manager.title, systemImage: "arrow.up.forward.app")
          }
        }
        Button {
          UIImpactFeedbackGenerator(style: .soft).impactOccurred()
          shareItem = PatcherShareItem(items: [session.resolvedOutput(result)])
        } label: {
          Label("Share Package", systemImage: "square.and.arrow.up")
        }
      }
      NavigationLink {
        ConversionLogView(result: result)
      } label: {
        Label("Conversion Log", systemImage: "doc.plaintext")
      }
    } header: {
      Text("Result")
    } footer: {
      if result.succeeded {
        Text("The converted package is ready to share or open in your package manager.")
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(session: ConversionSession())
  }
}
