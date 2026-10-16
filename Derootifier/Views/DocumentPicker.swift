import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
  let onSelect: (URL) -> Void

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    // Some providers do not declare the Debian UTI. Validate after selection.
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
    picker.allowsMultipleSelection = false
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
  func makeCoordinator() -> Coordinator { Coordinator(onSelect: onSelect) }

  final class Coordinator: NSObject, UIDocumentPickerDelegate {
    let onSelect: (URL) -> Void
    init(onSelect: @escaping (URL) -> Void) { self.onSelect = onSelect }

    func documentPicker(
      _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
    ) {
      guard let url = urls.first else { return }
      onSelect(url)
    }
  }
}
