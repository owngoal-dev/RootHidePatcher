import SwiftUI

enum AppBrand {
  static let name = "Umbra Patcher"
  static let sourceURL = URL(string: "https://github.com/owngoal-dev/RootHidePatcher")!
  static let upstreamURL = URL(string: "https://github.com/roothide/RootHidePatcher")!
}

/// Semantic surfaces and controls for Umbra Patcher.
enum PatcherStyle {
  static let accent = Color(uiColor: .dynamic(light: 0x278EFF, dark: 0x58A6FF))
  static let success = Color(uiColor: .systemGreen)
  static let failure = Color(uiColor: .systemRed)

  /// Black at the base level in the dark, a step off it in a sheet, so the
  /// cards (`card`) keep the same lift on both.
  static let page = Color(
    uiColor: UIColor { trait in
      guard trait.userInterfaceStyle == .dark else { return UIColor(hex: 0xF2F2F7) }
      return trait.userInterfaceLevel == .elevated ? UIColor(hex: 0x111111) : .black
    })
  static let card = Color(uiColor: .secondarySystemGroupedBackground)
  /// A sheet over the page: lifted off pure black in the dark, as system sheets are.
  static let drawer = Color(uiColor: .dynamic(light: 0xF2F2F7, dark: 0x1C1C1E))
  static let drawerCard = Color(uiColor: .dynamic(light: 0xFFFFFF, dark: 0x2C2C2E))
  static let well = Color(uiColor: .tertiarySystemFill)

  static let spacing: CGFloat = 12
  static let gutter: CGFloat = 16
  static let cardRadius: CGFloat = 18
  static let readableWidth: CGFloat = 640
}

extension UIColor {
  convenience init(hex: UInt32) {
    self.init(
      red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
  }

  static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
    UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) }
  }
}

/// The same arm64e artwork used by the installed app icon.
struct AppMark: View {
  @ScaledMetric private var size: CGFloat

  init(size: CGFloat = 52) {
    _size = ScaledMetric(wrappedValue: size, relativeTo: .title2)
  }

  var body: some View {
    Image("BrandIcon")
      .resizable()
      .interpolation(.high)
      .scaledToFit()
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: size * 0.224, style: .continuous))
      .accessibilityHidden(true)
  }
}

/// The surface every group of content sits on.
struct PatcherCard<Content: View>: View {
  var padding: CGFloat = PatcherStyle.gutter
  @ViewBuilder let content: Content

  var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: PatcherStyle.cardRadius, style: .continuous)
          .fill(PatcherStyle.card)
      )
  }
}

/// A group's name, set above its card.
struct SectionLabel: View {
  let title: LocalizedStringKey
  var trailing: String?

  init(_ title: LocalizedStringKey, trailing: String? = nil) {
    self.title = title
    self.trailing = trailing
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
      Spacer(minLength: 8)
      if let trailing { Text(verbatim: trailing).fontWeight(.regular) }
    }
    .font(.subheadline.weight(.semibold))
    .foregroundColor(.secondary)
    .padding(.horizontal, 4)
    .accessibilityAddTraits(.isHeader)
  }
}

/// A row inside a card: title, trailing chevron.
struct CardRow: View {
  let title: LocalizedStringKey

  var body: some View {
    HStack(spacing: PatcherStyle.spacing) {
      Text(title).foregroundColor(.primary)
      Spacer(minLength: 8)
      Image(systemName: "chevron.right")
        .font(.footnote.weight(.semibold))
        .foregroundColor(Color(uiColor: .tertiaryLabel))
        .accessibilityHidden(true)
    }
    .frame(minHeight: 44)
    .contentShape(Rectangle())
  }
}

struct PatcherShareItem: Identifiable {
  let id = UUID()
  let items: [Any]
}

/// Presented as a SwiftUI sheet, which also supplies the iPad presentation context.
struct PatcherShareSheet: UIViewControllerRepresentable {
  let items: [Any]
  /// The sheet dismisses itself when the user finishes; this tells SwiftUI.
  var onFinish: () -> Void = {}

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.completionWithItemsHandler = { _, _, _, _ in onFinish() }
    return controller
  }

  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
