import Foundation

// Executable Phase 0 integration check; not the GUI application's bridge.
let executable = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let contents = executable.deletingLastPathComponent().deletingLastPathComponent()
let node = contents.appendingPathComponent("Helpers/node")
let server = contents.appendingPathComponent("Resources/engine/protocol/server.js")
let process = Process()
process.executableURL = node
process.arguments = ["--max-old-space-size=128", server.path]
process.environment = ["PATH": "/usr/bin:/bin", "LANG": "en_US.UTF-8"]
process.currentDirectoryURL = contents
let input = Pipe(), output = Pipe()
process.standardInput = input
process.standardOutput = output
process.standardError = FileHandle.standardError
let finished = DispatchSemaphore(value: 0)
process.terminationHandler = { _ in finished.signal() }
do {
    try process.run()
    let request = Data("{\"jsonrpc\":\"2.0\",\"id\":\"probe\",\"method\":\"initialize\",\"params\":{\"protocolVersion\":1}}\n".utf8)
    try input.fileHandleForWriting.write(contentsOf: request)
    try input.fileHandleForWriting.close()
    guard finished.wait(timeout: .now() + 5) == .success else {
        process.terminate()
        throw NSError(domain: "BridgeProbe.Timeout", code: 1)
    }
    let data = output.fileHandleForReading.readDataToEndOfFile()
    guard process.terminationStatus == 0, data.count < 65536,
          let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          response["id"] as? String == "probe",
          let result = response["result"] as? [String: Any],
          result["protocolVersion"] as? Int == 1,
          result["executable"] as? String == node.path else {
        throw NSError(domain: "BridgeProbe.InvalidResponse", code: 2)
    }
    print(String(decoding: data, as: UTF8.self))
} catch {
    fputs("Bridge probe failed: \(error)\n", stderr)
    exit(1)
}
