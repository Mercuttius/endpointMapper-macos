import Foundation
import Darwin
import OSLog

struct EngineStatus: Decodable, Sendable {
    let protocolVersion: Int
    let engineVersion: String
    let capabilities: [String]
    let runtime: String
    let architecture: String
}
enum SessionEvent: Sendable {
    case notification(String, RPCValue)
    case disconnected(String)
}

// One serial writer prevents interleaved frames and keeps blocking pipe writes
// off both MainActor and the session actor. Requests are bounded to 32 × 8 KiB.
private final class PipeWriter: @unchecked Sendable {
    private let queue = DispatchQueue(label: "EndpointMapper.protocol.write")
    private let handle: FileHandle
    init(_ handle: FileHandle) { self.handle = handle }
    func write(_ data: Data, completion: @escaping @Sendable (Error?) -> Void) {
        queue.async {
            do { try self.handle.write(contentsOf: data); completion(nil) }
            catch { completion(error) }
        }
    }
}

actor AnalysisSession {
    private let logger = Logger(subsystem: "local.endpointmapper.app", category: "AnalysisSession")
    nonisolated let events: AsyncStream<SessionEvent>
    private let eventSink: AsyncStream<SessionEvent>.Continuation
    private let bundleURL: URL
    private let scriptOverride: URL?
    private var process: Process?
    private var input: Pipe?
    private var writer: PipeWriter?
    private var generation = UUID()
    private struct Pending {
        let method: String
        let continuation: CheckedContinuation<RPCValue, Error>
        let deadline: Task<Void, Never>
        var sequence = -1
    }
    private var pending: [String: Pending] = [:]
    private var retired: [String] = []
    private var cancellationWaits: Set<String> = []

    init(bundleURL: URL = Bundle.main.bundleURL, scriptOverride: URL? = nil) {
        self.bundleURL = bundleURL
        self.scriptOverride = scriptOverride
        var sink: AsyncStream<SessionEvent>.Continuation!
        events = AsyncStream(bufferingPolicy: .bufferingNewest(64)) { sink = $0 }
        eventSink = sink
    }
    func start() async throws -> EngineStatus {
        guard process == nil else { throw SessionError.overloaded }
        signal(SIGPIPE, SIG_IGN)
        let contents = bundleURL.appendingPathComponent("Contents")
        let process = Process(), input = Pipe(), output = Pipe()
        let token = UUID()
        generation = token
        process.executableURL = contents.appendingPathComponent("Helpers/node")
        process.arguments = ["--max-old-space-size=256", (scriptOverride ?? contents.appendingPathComponent("Resources/engine/protocol/server.js")).path]
        process.environment = ["PATH":"/usr/bin:/bin", "LANG":"en_US.UTF-8"]
        process.currentDirectoryURL = contents
        process.standardInput = input
        process.standardOutput = output
        // Never mix runtime diagnostics with protocol frames; no source is logged.
        process.standardError = FileHandle.standardError
        process.terminationHandler = { [weak self] _ in Task { await self?.ended(token) } }
        self.process = process
        self.input = input
        self.writer = PipeWriter(input.fileHandleForWriting)
        do { try process.run() }
        catch { fail(.disconnected); throw error }
        try? input.fileHandleForReading.close()
        try? output.fileHandleForWriting.close()
        let handle = output.fileHandleForReading
        // A dedicated reader avoids cross-handle head-of-line blocking in
        // Foundation's shared AsyncBytes machinery. Each frame is acknowledged
        // by the actor before reading more, bounding queued work and preserving order.
        DispatchQueue(label: "EndpointMapper.protocol.read").async { [weak self] in
            defer { try? handle.close() }
            var buffer = Data()
            do {
                var bytes = [UInt8](repeating: 0, count: 16384)
                while true {
                    let count = Darwin.read(handle.fileDescriptor, &bytes, bytes.count)
                    if count == 0 { break }
                    if count < 0 {
                        if errno == EINTR { continue }
                        throw SessionError.disconnected
                    }
                    buffer.append(contentsOf: bytes.prefix(count))
                    while let newline = buffer.firstIndex(of: 10) {
                        let frame = Data(buffer[..<newline])
                        guard frame.count <= 65536 else { throw SessionError.frameTooLarge }
                        buffer.removeSubrange(...newline)
                        let delivered = DispatchSemaphore(value: 0)
                        Task { await self?.receive(frame, token: token); delivered.signal() }
                        delivered.wait()
                    }
                    guard buffer.count <= 65536 else { throw SessionError.frameTooLarge }
                }
                let error: SessionError = buffer.isEmpty ? .disconnected : .malformed
                Task { await self?.broken(error, token: token) }
            } catch {
                let failure = (error as? SessionError) ?? .disconnected
                Task { await self?.broken(failure, token: token) }
            }
        }
        do {
            let value = try await request("initialize", params: .object(["protocolVersion":.number(1)]), timeout: 5)
            let status = try value.decode(EngineStatus.self)
            guard status.protocolVersion == 1 else { throw SessionError.malformed }
            return status
        } catch { if generation == token { fail(.disconnected) }; throw error }
    }
    func request(_ method: String, params: RPCValue = .object([:]), timeout: Double = 30, id: String = UUID().uuidString) async throws -> RPCValue {
        guard writer != nil else { throw SessionError.disconnected }
        guard pending.count < 32, pending[id] == nil, !id.isEmpty, id.utf8.count <= 128 else { throw SessionError.overloaded }
        guard timeout.isFinite, timeout > 0, timeout <= 3600 else { throw SessionError.malformed }
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                let token = generation
                let deadline = Task { [weak self] in
                    do { try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000)) }
                    catch { return }
                    await self?.expired(id, token: token)
                }
                pending[id] = Pending(method: method, continuation: continuation, deadline: deadline)
                send(id: id, method: method, params: params)
            }
        } onCancel: { Task { await self.cancel(id) } }
    }
    func scan(root: URL, timeout: Double = 120, requestID: String = UUID().uuidString) async throws -> Inventory {
        let value = try await request("project.scan", params: .object(["root":.string(root.path)]), timeout: timeout, id: requestID)
        do {
            let inventory = try value.decode(Inventory.self)
            guard (0...50000).contains(inventory.files), (0...50001).contains(inventory.directories),
                  inventory.ignored >= 0, inventory.symlinks >= 0, inventory.warnings.count <= 100,
                  inventory.languages.values.allSatisfy({ $0 >= 0 && $0 <= inventory.files }) else {
                throw SessionError.malformed
            }
            return inventory
        } catch { fail(.malformed); throw SessionError.malformed }
    }
    func stop() {
        // Closing stdin is part of the engine contract and aborts active scans.
        fail(.disconnected, notify: false)
    }
    private func send(id: String, method: String, params: RPCValue) {
        guard let writer else { fail(.disconnected); return }
        do {
            var data = try JSONEncoder().encode(RPCValue.object(["jsonrpc":.string("2.0"), "id":.string(id), "method":.string(method), "params":params]))
            guard data.count <= 8192 else { throw SessionError.frameTooLarge }
            data.append(10)
            let token = generation
            writer.write(data) { [weak self] error in
                if error != nil { Task { await self?.broken(.disconnected, token: token) } }
            }
        } catch { fail(.frameTooLarge) }
    }
    private func receive(_ data: Data, token: UUID) {
        guard token == generation, process != nil else { return }
        do {
            let frame = try JSONDecoder().decode(RPCValue.self, from: data)
            guard frame["jsonrpc"]?.string == "2.0" else { throw SessionError.malformed }
            if let method = frame["method"]?.string {
                guard frame["id"] == nil, ["project/progress", "project/batch"].contains(method),
                      let params = frame["params"], let id = params["requestId"]?.string else { throw SessionError.malformed }
                if retired.contains(id) { return }
                guard var entry = pending[id], entry.method == "project.scan",
                      let sequence = params["sequence"]?.number, sequence == Double(entry.sequence + 1),
                      let files = params["files"]?.number, files >= 0, files <= 50000, files.rounded() == files,
                      let directories = params["directories"]?.number, directories >= 0, directories <= 50001, directories.rounded() == directories,
                      case .array(let paths) = params["paths"], paths.count <= 16,
                      paths.allSatisfy({ value in
                          guard let path = value.string else { return false }
                          return !path.isEmpty && !path.hasPrefix("/") && !path.contains("\0") && path.utf8.count <= 2048 && !path.split(separator: "/").contains("..")
                      }) else { throw SessionError.malformed }
                entry.sequence += 1
                pending[id] = entry
                eventSink.yield(.notification(method, params))
                return
            }
            guard let id = frame["id"]?.string else { throw SessionError.malformed }
            if retired.contains(id) { cancellationWaits.remove(id); return }
            guard let entry = pending[id], (frame["result"] != nil) != (frame["error"] != nil) else { throw SessionError.malformed }
            let outcome: Result<RPCValue, Error>
            if let remote = frame["error"] {
                guard let code = remote["code"]?.number, code.rounded() == code, abs(code) < 1_000_000,
                      let message = remote["message"]?.string else { throw SessionError.malformed }
                outcome = .failure(code == -32800 ? SessionError.cancelled : SessionError.remote(Int(code), message))
            } else { outcome = .success(frame["result"]!) }
            pending.removeValue(forKey: id)
            entry.deadline.cancel()
            entry.continuation.resume(with: outcome)
        } catch { fail(.malformed) }
    }
    private func retire(_ id: String) { retired.append(id); if retired.count > 256 { retired.removeFirst() } }
    private func cancel(_ id: String) {
        guard let entry = pending.removeValue(forKey: id) else { return }
        entry.deadline.cancel()
        retire(id)
        entry.continuation.resume(throwing: SessionError.cancelled)
        guard entry.method == "project.scan" else { return }
        cancellationWaits.insert(id)
        let cancellationID = UUID().uuidString
        retire(cancellationID)
        send(id: cancellationID, method: "cancel", params: .object(["requestId":.string(id)]))
        let token = generation
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await self?.checkCancellation(id, token: token)
        }
    }
    private func checkCancellation(_ id: String, token: UUID) {
        if generation == token, cancellationWaits.contains(id) { fail(.timeout) }
    }
    private func expired(_ id: String, token: UUID) {
        if generation == token, pending[id] != nil { fail(.timeout) }
    }
    private func ended(_ token: UUID) { broken(.disconnected, token: token) }
    private func broken(_ error: SessionError, token: UUID) {
        if token == generation, process != nil { fail(error) }
    }
    private func fail(_ error: SessionError, notify: Bool = true) {
        let old = process
        generation = UUID()
        process = nil
        writer = nil
        try? input?.fileHandleForWriting.close()
        input = nil
        let waiting = Array(pending.values)
        pending.removeAll()
        for entry in waiting { entry.deadline.cancel(); entry.continuation.resume(throwing: error) }
        cancellationWaits.removeAll()
        retired.removeAll()
        if let old, old.isRunning {
            old.terminate()
            Task.detached {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if old.isRunning { kill(old.processIdentifier, SIGKILL) }
            }
        }
        if notify, old != nil {
            logger.error("Engine session ended: \(error.localizedDescription, privacy: .public)")
            eventSink.yield(.disconnected(error.localizedDescription))
        }
    }
}
