import SwiftUI

/// The build copies the source notices; only whitespace is reflowed for display.
struct LicenseListView: View {
  private var notices: [URL] {
    (Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "Licenses") ?? [])
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  var body: some View {
    List(notices, id: \.self) { url in
      NavigationLink {
        ScrollView {
          Text(verbatim: LicenseText.reflow((try? String(contentsOf: url, encoding: .utf8)) ?? ""))
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

enum LicenseText {
  /// Remove fixed-width wrapping while retaining paragraph and notice boundaries.
  static func reflow(_ source: String) -> String {
    let normalized = source
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
    var paragraphs: [[String]] = []
    var lines: [String] = []
    for rawLine in normalized.components(separatedBy: "\n") {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.isEmpty {
        if !lines.isEmpty {
          paragraphs.append(lines)
          lines.removeAll(keepingCapacity: true)
        }
      } else {
        lines.append(line)
      }
    }
    if !lines.isEmpty { paragraphs.append(lines) }

    return paragraphs.map { paragraph in
      var result = paragraph[0]
      for index in 1..<paragraph.count {
        let line = paragraph[index]
        let previous = paragraph[index - 1]
        // Titles/versions, copyright notices and list entries have meaningful
        // line breaks even when the source does not leave an empty line.
        let startsEntry = line.range(
          of: #"^(?:Version\s+\d|Copyright\b|(?:\d+[.)]|[a-z][.)]|[-*•])\s+)"#,
          options: .regularExpression) != nil
        let followsCopyright = previous.contains("Copyright (C)")
          || previous.contains("Copyright (c)")
        result += (startsEntry || followsCopyright ? "\n" : " ") + line
      }
      return result
    }.joined(separator: "\n\n")
  }
}
