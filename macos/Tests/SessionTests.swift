import XCTest
@testable import EndpointMapper

final class SessionTests: XCTestCase {
    private func fixture(_ body: String) throws -> (AnalysisSession, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let script = directory.appendingPathComponent("fixture.mjs")
        // Deliberately faulty peers exist only in tests, never in production resources.
        let source = """
        import readline from 'node:readline';
        const send = x => process.stdout.write(JSON.stringify(x)+'\\n');
        let scanID, cancelled = false;
        readline.createInterface({input:process.stdin}).on('line', line => {
          const r = JSON.parse(line);
          if(r.method==='initialize') {
            send({jsonrpc:'2.0',id:r.id,result:{protocolVersion:1,engineVersion:'test',capabilities:['project.scan'],runtime:process.version,architecture:process.arch}});
            return;
          }
          \(body)
        });
        """
        try source.write(to: script, atomically: true, encoding: .utf8)
        return (AnalysisSession(scriptOverride: script), directory)
    }
    func testPersistentConcurrentRequestsAndRealInventory() async throws {
        let session = AnalysisSession()
        _ = try await session.start()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("api.ts")
        let source = "throw new Error('must not execute');"
        try source.write(to: file, atomically: true, encoding: .utf8)
        async let first = session.request("ping")
        async let second = session.request("ping")
        let values = try await [first, second]
        XCTAssertEqual(values, [.object(["alive":.bool(true)]), .object(["alive":.bool(true)])])
        let result = try await session.scan(root: directory)
        XCTAssertEqual(result.files, 1)
        XCTAssertEqual(result.languages["TypeScript"], 1)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), source)
        await session.stop()
    }
    func testTimeoutFailsAndRestartWorks() async throws {
        let (session, directory) = try fixture("// deliberately no reply")
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try await session.start()
        do { _ = try await session.request("ping", timeout: 0.05); XCTFail("Expected timeout") }
        catch { guard case SessionError.timeout = error else { return XCTFail("\(error)") } }
        _ = try await session.start()
        await session.stop()
    }
    func testCrashRejectsPendingRequests() async throws {
        let (session, directory) = try fixture("process.exit(7);")
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try await session.start()
        do { _ = try await session.request("crash"); XCTFail("Expected process failure") }
        catch { guard case SessionError.disconnected = error else { return XCTFail("\(error)") } }
        await session.stop()
    }
    func testMalformedReplyDisconnects() async throws {
        let (session, directory) = try fixture("process.stdout.write('not-json\\n');")
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try await session.start()
        do { _ = try await session.request("ping"); XCTFail("Expected malformed response") }
        catch { guard case SessionError.malformed = error else { return XCTFail("\(error)") } }
        await session.stop()
    }
    func testOversizedReplyDisconnects() async throws {
        let (session, directory) = try fixture("process.stdout.write('x'.repeat(65537));")
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try await session.start()
        do { _ = try await session.request("ping"); XCTFail("Expected size limit") }
        catch { guard case SessionError.frameTooLarge = error else { return XCTFail("\(error)") } }
        await session.stop()
    }
    func testCancellationReachesPeerAndPreservesSession() async throws {
        let (session, directory) = try fixture("""
        if(r.method==='project.scan') {
          scanID=r.id;
          send({jsonrpc:'2.0',method:'project/progress',params:{requestId:r.id,sequence:0,files:0,directories:0,paths:[]}});
        } else if(r.method==='cancel') {
          cancelled=true;
          send({jsonrpc:'2.0',id:scanID,error:{code:-32800,message:'Cancelled'}});
          send({jsonrpc:'2.0',id:r.id,result:{cancelled:true}});
        } else send({jsonrpc:'2.0',id:r.id,result:{cancelled}});
        """)
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try await session.start()
        var events = session.events.makeAsyncIterator()
        let scan = Task { try await session.scan(root: directory) }
        _ = await events.next()
        scan.cancel()
        do { _ = try await scan.value; XCTFail("Expected cancellation") }
        catch { guard case SessionError.cancelled = error else { return XCTFail("\(error)") } }
        let reply = try await session.request("ping")
        XCTAssertEqual(reply["cancelled"], .bool(true))
        await session.stop()
    }
    func testFragmentedResponseDecodes() async throws {
        let (session, directory) = try fixture("""
        const responseLine=JSON.stringify({jsonrpc:'2.0',id:r.id,result:{text:'árvore'}})+'\\n';
        for(const byte of Buffer.from(responseLine)) process.stdout.write(Buffer.from([byte]));
        """)
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try await session.start()
        let response = try await session.request("ping")
        XCTAssertEqual(response["text"], .string("árvore"))
        await session.stop()
    }
}
