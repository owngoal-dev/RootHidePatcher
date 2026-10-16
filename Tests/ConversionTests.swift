import XCTest

@testable import Patcher

final class ConversionTests: XCTestCase {
  func testScriptArguments() {
    XCTAssertEqual(ConversionMode.allCases.count, 3)
    XCTAssertEqual(ConversionMode.direct.argument, "")
    XCTAssertEqual(ConversionMode.compatibility.argument, "AutoPatches")
    XCTAssertEqual(ConversionMode.dynamic.argument, "DynamicPatches")
  }

  func testOutputNamesRemainCompatible() {
    let examples = [
      ("example_1.0_iphoneos-arm64.deb", "example_1.0_iphoneos-arm64e.deb"),
      ("example_1.0_iphoneos-arm.deb", "example_1.0_iphoneos-arm64e.deb"),
      ("A tweak 1.2.deb", "A tweak 1.2.deb"),
    ]
    for (input, output) in examples {
      XCTAssertEqual(
        ConversionMode.outputURL(for: URL(fileURLWithPath: "/imports/\(input)")).path,
        "/var/mobile/RootHidePatcher/\(output)")
    }
  }

  @MainActor
  func testImportPreservesSourceAndResetsMode() throws {
    let source = try fixture()
    defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
    let session = ConversionSession()
    XCTAssertEqual(session.mode, .compatibility)
    session.mode = .dynamic
    session.importFile(source)
    XCTAssertNil(session.issue)
    XCTAssertEqual(session.mode, .compatibility)
    let imported = try XCTUnwrap(session.selectedFile)
    defer { try? FileManager.default.removeItem(at: imported) }
    XCTAssertNotEqual(imported, source)
    XCTAssertEqual(try Data(contentsOf: source), try Data(contentsOf: imported))
    XCTAssertNotNil(session.fileSize)
  }

  @MainActor
  func testSameNameReplacementAndSamePathImport() throws {
    let source = try fixture()
    defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
    let session = ConversionSession()
    session.importFile(source)
    let imported = try XCTUnwrap(session.selectedFile)
    defer { try? FileManager.default.removeItem(at: imported) }
    let replacement = Data("second package".utf8)
    try replacement.write(to: source)
    session.importFile(source)
    XCTAssertNil(session.issue)
    XCTAssertEqual(try Data(contentsOf: imported), replacement)
    session.importFile(imported)
    XCTAssertNil(session.issue)
    XCTAssertEqual(try Data(contentsOf: imported), replacement)
  }

  @MainActor
  func testInvalidImportKeepsPreviousSelection() throws {
    let source = try fixture()
    defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
    let session = ConversionSession()
    session.importFile(source)
    let imported = try XCTUnwrap(session.selectedFile)
    defer { try? FileManager.default.removeItem(at: imported) }
    let invalid = source.deletingPathExtension().appendingPathExtension("txt")
    try Data("not a package".utf8).write(to: invalid)
    session.importFile(invalid)
    XCTAssertNotNil(session.issue)
    XCTAssertEqual(session.selectedFile, imported)
    XCTAssertEqual(try Data(contentsOf: imported), Data("test package bytes".utf8))
    session.issue = nil
    session.importFile(source.appendingPathExtension("missing"))
    XCTAssertNotNil(session.issue)
    XCTAssertEqual(session.selectedFile, imported)
  }

  @MainActor
  func testSimulatorNeverClaimsConversionSuccess() throws {
    #if targetEnvironment(simulator)
      let source = try fixture()
      defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
      let session = ConversionSession()
      session.importFile(source)
      let imported = try XCTUnwrap(session.selectedFile)
      defer { try? FileManager.default.removeItem(at: imported) }
      session.convert()
      XCTAssertNotNil(session.issue)
      XCTAssertFalse(session.isConverting)
      XCTAssertNil(session.result)
      XCTAssertEqual(session.selectedFile, imported)
    #endif
  }

  private func fixture() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("test-\(UUID().uuidString)_iphoneos-arm64.deb")
    try Data("test package bytes".utf8).write(to: url)
    return url
  }
}
