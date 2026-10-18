import SwiftUI
import UniformTypeIdentifiers

/// One button in the middle, options in a drawer below it.
struct ContentView: View {
  // Providers may associate .deb with different registered types. Resolve the
  // extension instead of requiring one identifier; importFile checks it again.
  private static let packageTypes = UTType.types(
    tag: "deb", tagClass: .filenameExtension, conformingTo: nil)
  @ObservedObject var session: ConversionSession
  @State private var showingPicker = false
  @State private var showingAbout = false
  @State private var shareItem: PatcherShareItem?
  @State private var pendingImport: URL?
  @State private var drawerOpen = false
  @State private var drawerHeight: CGFloat = 0
  @State private var showingLog = false
  /// Export was tapped: the button has split into the places a package can go.
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @State private var choosingExport = false

  var body: some View {
    NavigationView {
      ZStack(alignment: .bottom) {
        PatcherStyle.page.ignoresSafeArea()
        GeometryReader { geometry in
          let lift = lift(in: geometry.size.height)
          ScrollView {
            main
              .padding(.horizontal, PatcherStyle.gutter)
              // Clear of the wordmark above and the drawer's pill below.
              .padding(.top, 44)
              .padding(.bottom, 60)
              .frame(maxWidth: .infinity, minHeight: geometry.size.height)
              // The page makes room for the open drawer instead of sitting under it.
              .offset(y: -lift.offset)
              .opacity(lift.opacity)
          }
        }
        VStack {
          wordmark
          Spacer()
        }
        if drawerOpen {
          // Tapping the page above closes the drawer, before anything on it.
          Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .onTapGesture { withAnimation(OptionsDrawer.spring) { drawerOpen = false } }
            .accessibilityHidden(true)
        }
        OptionsDrawer(
          session: session, isOpen: $drawerOpen, cardHeight: $drawerHeight,
          chooseAnother: {
            withAnimation(OptionsDrawer.spring) { drawerOpen = false }
            choosePackage()
          },
          showLog: {
            withAnimation(OptionsDrawer.spring) { drawerOpen = false }
            showingLog = true
          },
          showAbout: {
            withAnimation(OptionsDrawer.spring) { drawerOpen = false }
            showingAbout = true
          }
        )
        if let result = session.result {
          NavigationLink(isActive: $showingLog) {
            ConversionLogView(result: result)
          } label: {
            EmptyView()
          }
          .hidden()
        }
      }
      .navigationTitle("Patcher")
      .navigationBarHidden(true)
    }
    .navigationViewStyle(.stack)
    .tint(PatcherStyle.accent)
    // SwiftUI's own importer: a picker that closes itself after a pick does not
    // reliably reach a sheet's onDismiss, so the package is taken from here.
    .fileImporter(isPresented: $showingPicker, allowedContentTypes: Self.packageTypes) { picked in
      switch picked {
      case .success(let url): convert(url)
      case .failure(let error):
        session.issue = PatcherIssue(
          title: String(localized: "Unable to Import"), message: error.localizedDescription)
      }
    }
    .onChange(of: showingPicker) { open in
      if !open { DispatchQueue.main.async { importPendingFile() } }
    }
    .sheet(isPresented: $showingAbout, onDismiss: importPendingFile) { CreditsView() }
    .sheet(item: $shareItem, onDismiss: importPendingFile) { item in
      PatcherShareSheet(items: item.items) { shareItem = nil }
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
        convert(url)
      }
    }
    // A new package or a new run puts the single button back.
    .onChange(of: session.isConverting) { converting in if converting { choosingExport = false } }
    .onChange(of: session.selectedFile) { _ in choosingExport = false }
  }

  // MARK: Actions

  /// A package goes straight into conversion, from the picker or another app.
  private func convert(_ url: URL) {
    session.importFile(url)
    guard session.issue == nil, session.selectedFile != nil, !session.isConverting else { return }
    session.convert()
  }

  private func importPendingFile() {
    guard let url = pendingImport else { return }
    pendingImport = nil
    convert(url)
  }

  private func choosePackage() {
    UISelectionFeedbackGenerator().selectionChanged()
    showingPicker = true
  }

  private var action: MainAction {
    if session.isConverting { return .converting }
    if let result = session.result {
      if result.succeeded && session.selectedFile == nil { return .export }
      if !result.succeeded { return .retry }
    }
    return session.selectedFile == nil ? .choose : .convert
  }

  private func perform() {
    switch action {
    case .choose: choosePackage()
    case .convert, .retry: session.convert()
    case .export:
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      // A soft spring, so the division overshoots a little and settles.
      withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) { choosingExport = true }
    case .converting: break
    }
  }

  // MARK: Layout

  /// How far the page rises to stay clear of the open drawer, centring the
  /// tile in the space left above it. Where that space is too short for the
  /// tile, as on a phone on its side, the page drifts up and fades instead,
  /// and comes back when the drawer closes.
  private func lift(in height: CGFloat) -> (offset: CGFloat, opacity: Double) {
    guard drawerOpen else { return (0, 1) }
    let pill: CGFloat = 60
    let rise = max(drawerHeight - pill, 0) / 2
    let room = height - drawerHeight - 44
    let fits = room >= tileSide + 60
    return fits ? (rise, 1) : (rise + 40, 0)
  }

  private var tileSide: CGFloat {
    if verticalSizeClass == .compact { return 150 }
    return horizontalSizeClass == .regular ? 260 : 216
  }

  /// The tile, and at most one quiet line under it.
  private var main: some View {
    VStack(spacing: 22) {
      PackageTile(
        action: action, routes: routes, isSplit: choosingExport, side: tileSide,
        perform: perform)
      caption
        .font(.footnote)
        .foregroundColor(.secondary)
        .lineLimit(1)
        .truncationMode(.middle)
        .frame(maxWidth: 300, minHeight: 18)
        .accessibilityElement(children: .combine)
    }
  }

  /// A small mark of the app at the top, far enough from the tile to stay quiet.
  private var wordmark: some View {
    HStack(spacing: 8) {
      AppMark(size: 22)
      Text(verbatim: AppBrand.name)
        .font(.footnote.weight(.semibold))
        .foregroundColor(.secondary)
    }
    .padding(.top, 12)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }

  @ViewBuilder private var caption: some View {
    switch action {
    case .choose:
      Text(verbatim: "")
    case .converting, .convert:
      if let file = session.selectedFile { Text(verbatim: file.lastPathComponent) }
    case .export:
      if let result = session.result {
        HStack(spacing: 5) {
          Image(systemName: "checkmark.circle.fill").foregroundColor(PatcherStyle.success)
          Text(verbatim: result.output.lastPathComponent)
        }
      }
    case .retry:
      if let result = session.result {
        Text("Conversion Failed: \(result.exitCode)")
      }
    }
  }

  /// The destinations the tile divides into on Export.
  private var routes: [ExportRoute] {
    guard action == .export, let result = session.result else { return [] }
    let output = session.resolvedOutput(result)
    return [
      ExportRoute(id: "share", title: String(localized: "Share"), symbol: "square.and.arrow.up") {
        shareItem = PatcherShareItem(items: [output])
      },
    ]
      + session.availableManagers.map { manager in
        ExportRoute(id: manager.identifier, title: manager.title, symbol: "arrow.up.forward.app") {
          session.openResult(in: manager)
        }
      }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(session: ConversionSession())
  }
}
