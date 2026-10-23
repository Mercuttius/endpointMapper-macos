import Foundation

// Compatibility helper for callers that only need a one-shot health check.
// The application owns a persistent AnalysisSession instead.
enum EngineHealth {
    static func check(bundleURL: URL) async throws -> EngineStatus {
        let session = AnalysisSession(bundleURL: bundleURL)
        do {
            let status = try await session.start()
            await session.stop()
            return status
        } catch { await session.stop(); throw error }
    }
}
