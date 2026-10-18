import SwiftUI

enum ConversionMode: String, CaseIterable, Identifiable {
  case direct, compatibility, dynamic
  var id: String { rawValue }

  // These arguments are the existing patch.sh contract.
  var argument: String {
    switch self {
    case .direct: return ""
    case .compatibility: return "AutoPatches"
    case .dynamic: return "DynamicPatches"
    }
  }

  var title: String {
    switch self {
    case .direct: return String(localized: "Direct Conversion")
    case .compatibility: return String(localized: "Rootless Compatibility")
    case .dynamic: return String(localized: "Dynamic Patches")
    }
  }

  var detail: String {
    switch self {
    case .direct:
      return String(localized: "For simple tweaks. Also supports eligible rootful packages.")
    case .compatibility:
      return String(localized: "Uses the Rootless Compat Layer. Selected by default.")
    case .dynamic:
      return String(localized: "Requires a matching dynamic patch package for the tweak.")
    }
  }

  static func outputURL(for input: URL) -> URL {
    let name = input.deletingPathExtension().lastPathComponent
      .replacingOccurrences(of: "iphoneos-arm64", with: "-a-r-c-h-")
      .replacingOccurrences(of: "iphoneos-arm", with: "-a-r-c-h-")
      .replacingOccurrences(of: "-a-r-c-h-", with: "iphoneos-arm64e")
    return URL(fileURLWithPath: "/var/mobile/RootHidePatcher/\(name).deb")
  }
}

struct ConversionResult {
  let output: URL
  let exitCode: Int
  let log: String
  var succeeded: Bool { exitCode == 0 }
}

struct PatcherIssue: Identifiable {
  let id = UUID()
  let title: String
  let message: String
}

struct PackageManager {
  let identifier: String
  let title: String
}

/// Owned by the app, so file-open events and view redraws share one transaction.
@MainActor
final class ConversionSession: ObservableObject {
  @Published private(set) var selectedFile: URL?
  @Published private(set) var fileSize: String?
  @Published var mode: ConversionMode = .compatibility
  @Published private(set) var isConverting = false
  @Published private(set) var result: ConversionResult?
  @Published var issue: PatcherIssue?

  var availableManagers: [PackageManager] {
    #if targetEnvironment(simulator)
      return []
    #else
      let managers = [
        PackageManager(identifier: "wiki.qaq.irisin", title: String(localized: "Open in Irisin")),
        PackageManager(identifier: "org.coolstar.SileoStore", title: String(localized: "Open in Sileo")),
        PackageManager(identifier: "xyz.willy.Zebra", title: String(localized: "Open in Zebra")),
      ]
      guard let preferred = managers.first(where: { IsAppAvailable($0.identifier) }) else {
        return []
      }
      return [preferred]
    #endif
  }

  func importFile(_ source: URL) {
    guard !isConverting else {
      issue = PatcherIssue(
        title: String(localized: "Conversion in Progress"),
        message: String(
          localized: "Wait for the current conversion to finish before opening another package."))
      return
    }
    let scoped = source.startAccessingSecurityScopedResource()
    defer { if scoped { source.stopAccessingSecurityScopedResource() } }
    do {
      let values = try source.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
      guard source.pathExtension.lowercased() == "deb", values.isRegularFile == true else {
        issue = PatcherIssue(
          title: String(localized: "Unable to Import"),
          message: String(localized: "Select a .deb package."))
        return
      }
      let manager = FileManager.default
      #if targetEnvironment(simulator)
        let inbox = manager.temporaryDirectory.appendingPathComponent(
          "RootHidePatcher/.Inbox", isDirectory: true)
      #else
        let inbox = URL(
          fileURLWithPath: jbroot("/var/mobile/RootHidePatcher/.Inbox"), isDirectory: true)
      #endif
      try manager.createDirectory(at: inbox, withIntermediateDirectories: true)
      let destination = inbox.appendingPathComponent(source.lastPathComponent)
      if source.resolvingSymlinksInPath() != destination.resolvingSymlinksInPath() {
        // Copy first: a provider error must not destroy the previous import.
        let staged = inbox.appendingPathComponent(UUID().uuidString)
        defer { try? manager.removeItem(at: staged) }
        try manager.copyItem(at: source, to: staged)
        if manager.fileExists(atPath: destination.path) {
          _ = try manager.replaceItemAt(destination, withItemAt: staged)
        } else {
          try manager.moveItem(at: staged, to: destination)
        }
      }
      selectedFile = destination
      fileSize = values.fileSize.map {
        ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file)
      }
      // The method is chosen before the package and is kept between packages.
      result = nil
    } catch {
      issue = PatcherIssue(
        title: String(localized: "Unable to Import"), message: error.localizedDescription)
    }
  }

  func convert() {
    guard !isConverting, let input = selectedFile else { return }
    #if targetEnvironment(simulator)
      issue = PatcherIssue(
        title: String(localized: "Device Required"),
        message: String(
          localized:
            "Conversion requires a device with a RootHide environment. The simulator can preview the interface only."
        ))
    #else
      guard let script = Bundle.main.path(forResource: "patch", ofType: "sh") else {
        issue = PatcherIssue(
          title: String(localized: "Unable to Convert"),
          message: String(localized: "The conversion script is missing from this installation."))
        return
      }
      let output = ConversionMode.outputURL(for: input)
      let argument = mode.argument
      let previousIdleTimer = UIApplication.shared.isIdleTimerDisabled
      isConverting = true
      result = nil
      UIApplication.shared.isIdleTimerDisabled = true
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      DispatchQueue.global(qos: .userInitiated).async {
        let (code, log) = repackDeb(
          scriptPath: script, debURL: input, outputURL: output, patch: argument)
        DispatchQueue.main.async {
          UIApplication.shared.isIdleTimerDisabled = previousIdleTimer
          self.result = ConversionResult(output: output, exitCode: code, log: log)
          self.isConverting = false
          if code == 0 {
            self.selectedFile = nil
            self.fileSize = nil
          }
          UINotificationFeedbackGenerator().notificationOccurred(code == 0 ? .success : .error)
        }
      }
    #endif
  }

  func resolvedOutput(_ result: ConversionResult) -> URL {
    URL(fileURLWithPath: jbroot(result.output.path))
  }

  func openResult(in manager: PackageManager) {
    guard let result = result, result.succeeded else { return }
    if !ShareFileToApp(manager.identifier, resolvedOutput(result).path) {
      issue = PatcherIssue(
        title: String(localized: "Unable to Open Package"),
        message: String(
          localized:
            "The package manager could not open this file. You can still use Share Package."))
    }
  }
}
