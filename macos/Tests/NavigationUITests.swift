import XCTest
import AppKit

final class NavigationUITests: XCTestCase {
    override func setUp() { super.setUp(); continueAfterFailure = false }
    func testLaunchAndNavigation() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Explore suas APIs"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Abrir projeto"].firstMatch.exists)
        XCTAssertLessThan(app.windows.firstMatch.frame.height, 900)
        let screenshot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        screenshot.name = "Native Workspace"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Endpoints"].click()
        XCTAssertTrue(app.staticTexts["Endpoints: próxima etapa"].waitForExistence(timeout: 3))
        app.buttons["Projeto"].click()
        XCTAssertTrue(app.staticTexts["Seu código permanece no seu Mac"].exists)
        app.terminate()
    }
    func testInventoryThroughNativePicker() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("EndpointMapperUITest-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("node_modules"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("api.ts")
        let source = "throw new Error('never execute this project');"
        try source.write(to: file, atomically: true, encoding: .utf8)
        try "ignored".write(to: root.appendingPathComponent("node_modules/dep.js"), atomically: true, encoding: .utf8)
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Explore suas APIs"].waitForExistence(timeout: 15))
        app.buttons["Abrir projeto"].firstMatch.click()
        app.typeKey("g", modifierFlags: [.command, .shift])
        let pathField = app.textFields["PathTextField"]
        XCTAssertTrue(pathField.waitForExistence(timeout: 5))
        pathField.click()
        pathField.typeKey("a", modifierFlags: [.command])
        // Long synthesized typing can drop characters in the system Go To sheet.
        let clipboard = NSPasteboard.general
        let saved = (clipboard.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }
        defer {
            clipboard.clearContents()
            clipboard.writeObjects(saved.map { entries in
                let item = NSPasteboardItem()
                for (type, data) in entries { item.setData(data, forType: type) }
                return item
            })
        }
        clipboard.clearContents()
        clipboard.setString(root.path + "/", forType: .string)
        pathField.typeKey("v", modifierFlags: [.command])
        XCTAssertEqual(pathField.value as? String, root.path + "/")
        pathField.typeKey(.return, modifierFlags: [])
        let confirm = app.buttons["OKButton"].firstMatch
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: pathField)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 20), .completed, app.debugDescription)
        confirm.click()
        XCTAssertTrue(app.buttons["Inventariar arquivos"].waitForExistence(timeout: 5), app.debugDescription)
        app.buttons["Inventariar arquivos"].click()
        XCTAssertTrue(app.staticTexts["Inventário concluído. Nenhuma análise de endpoints foi realizada."].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Arquivos identificados: 1"].exists)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), source)
        let screenshot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        screenshot.name = "Inventory Result"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
    }

}
