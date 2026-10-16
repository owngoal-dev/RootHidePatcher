import SwiftUI

/// Semantic colors and a small layout scale, following the studio's native utilities.
enum PatcherStyle {
  static let accent = Color(uiColor: .systemBlue)
  static let background = Color(uiColor: .systemGroupedBackground)
  static let success = Color(uiColor: .systemGreen)
  static let failure = Color(uiColor: .systemRed)
  static let unselected = Color(uiColor: .tertiaryLabel)
  static let spacing: CGFloat = 12
  static let readableWidth: CGFloat = 680
}

struct PatcherShareItem: Identifiable {
  let id = UUID()
  let items: [Any]
}

/// Presented as a SwiftUI sheet, which also supplies the iPad presentation context.
struct PatcherShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
