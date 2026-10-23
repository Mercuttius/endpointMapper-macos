import XCTest
import AppKit
import SwiftUI
@testable import EndpointMapper

final class FoundationTests: XCTestCase {
    @MainActor func testFontsAndBrandingAreBundled() throws {
        try Theme.registerFonts()
        for weight in ["Regular", "Medium", "SemiBold", "Bold"] {
            XCTAssertNotNil(NSFont(name: "JetBrainsMono-\(weight)", size: 13))
        }
        XCTAssertNotNil(Theme.logo)
    }
    func testBundledEngineHandshake() async throws {
        let status = try await EngineHealth.check(bundleURL: Bundle.main.bundleURL)
        XCTAssertEqual(status.protocolVersion, 1)
        XCTAssertTrue(status.capabilities.contains("project.scan"))
    }
    func testMissingEngineFails() async {
        do {
            _ = try await EngineHealth.check(bundleURL: URL(fileURLWithPath: "/nonexistent-endpointmapper-test"))
            XCTFail("Missing helper must fail")
        } catch { }
    }
    @MainActor func testProjectSelectionRejectsFilesAndAcceptsDirectory() throws {
        let status = EngineStatus(protocolVersion: 1, engineVersion: "test", capabilities: [], runtime: "test", architecture: "test")
        let model = WorkspaceModel(engine: status)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("sentinel.txt")
        let data = Data("unchanged".utf8)
        try data.write(to: file)
        model.select(file)
        XCTAssertNotNil(model.issue)
        XCTAssertNil(model.project)
        model.select(directory)
        XCTAssertNil(model.issue)
        XCTAssertEqual(model.project, directory.standardizedFileURL)
        XCTAssertEqual(try Data(contentsOf: file), data)
    }
    func testSymbolsExist() {
        for symbol in ["folder", "folder.badge.plus", "point.3.connected.trianglepath.dotted", "point.topleft.down.curvedto.point.bottomright.up", "exclamationmark.triangle", "lock.shield", "sidebar.right", "lock.doc", "xmark.circle", "folder.badge.gearshape", "checkmark.circle", "gearshape", "textformat.size", "info.circle", "doc.text", "arrow.clockwise", "xmark"] {
            XCTAssertNotNil(NSImage(systemSymbolName: symbol, accessibilityDescription: nil), symbol)
        }
    }

}
