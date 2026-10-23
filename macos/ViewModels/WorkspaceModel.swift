import AppKit
import SwiftUI

@MainActor final class WorkspaceModel: ObservableObject {
    @Published var project: URL?
    @Published var issue: String?
    @Published var section = "Projeto"
    @Published private(set) var engine: EngineStatus
    @Published private(set) var connected = true
    @Published private(set) var reconnecting = false
    @Published private(set) var scanning = false
    @Published private(set) var filesSeen = 0
    @Published private(set) var recentPaths: [String] = []
    @Published private(set) var inventory: Inventory?
    @Published private(set) var scanMessage: String?
    private let session: AnalysisSession
    private var eventTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?
    private var scanID: String?
    init(engine: EngineStatus, session: AnalysisSession = AnalysisSession()) {
        self.engine = engine
        self.session = session
        let events = session.events
        eventTask = Task { [weak self] in
            for await event in events {
                guard let self else { return }
                switch event {
                case .notification(_, let params):
                    guard self.scanning, params["requestId"]?.string == self.scanID else { continue }
                    self.filesSeen = Int(params["files"]?.number ?? 0)
                    if case .array(let paths) = params["paths"] {
                        self.recentPaths = Array((self.recentPaths + paths.compactMap(\.string)).suffix(100))
                    }
                case .disconnected(let message):
                    self.connected = false
                    self.scanning = false
                    self.scanID = nil
                    self.scanTask?.cancel()
                    self.scanMessage = message
                }
            }
        }
    }
    deinit { eventTask?.cancel(); scanTask?.cancel() }
    func openProject() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Abrir projeto"
        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in self?.select(url) }
        }
        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
        }
    }
    func select(_ url: URL) {
        do {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isReadableKey])
            guard url.isFileURL, values.isDirectory == true, values.isReadable == true else {
                throw BootstrapError.message("Selecione uma pasta local com permissão de leitura.")
            }
            closeProject()
            project = url.standardizedFileURL
            issue = nil
            section = "Projeto"
        } catch { issue = error.localizedDescription }
    }
    func closeProject() {
        cancelScan()
        project = nil
        inventory = nil
        scanMessage = nil
        filesSeen = 0
        recentPaths = []
    }
    func startScan() {
        guard let root = project, connected, !scanning else { return }
        let id = UUID().uuidString
        scanID = id
        scanning = true
        inventory = nil
        recentPaths = []
        filesSeen = 0
        scanMessage = nil
        let configured = UserDefaults.standard.double(forKey: "analysisTimeout")
        let timeout = configured > 0 ? min(max(configured, 5), 3600) : 120
        scanTask = Task { [weak self, session] in
            do {
                let result = try await session.scan(root: root, timeout: timeout, requestID: id)
                guard let self, self.scanID == id else { return }
                self.inventory = result
                self.filesSeen = result.files
                self.scanning = false
                self.scanMessage = result.truncated || !result.warnings.isEmpty ? "Inventário parcial; consulte os avisos." : "Inventário concluído. Nenhuma análise de endpoints foi realizada."
                self.scanID = nil
            } catch {
                guard let self, self.scanID == id else { return }
                self.scanning = false
                self.scanMessage = error.localizedDescription
                self.scanID = nil
            }
        }
    }
    func cancelScan() {
        scanID = nil
        scanTask?.cancel()
        scanTask = nil
        if scanning {
            filesSeen = 0
            scanMessage = "Inventário cancelado; resultados parciais descartados."
        }
        scanning = false
        inventory = nil
        recentPaths = []
    }
    func reconnect() {
        guard !reconnecting else { return }
        reconnecting = true
        connected = false
        cancelScan()
        Task {
            await session.stop()
            do { engine = try await session.start(); connected = true; scanMessage = nil }
            catch { scanMessage = error.localizedDescription }
            reconnecting = false
        }
    }
}
