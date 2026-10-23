import SwiftUI
import AppKit

@main struct EndpointMapperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        Settings { PreferencesView() }
            .commands {
                CommandGroup(replacing: .appInfo) {
                    Button { delegate.showAbout() } label: { Label("Sobre Endpoint Mapper", systemImage: "info.circle") }
                }
                CommandGroup(replacing: .newItem) {
                    Button { delegate.model?.openProject() } label: { Label("Abrir projeto…", systemImage: "folder.badge.plus") }
                        .keyboardShortcut("o").disabled(delegate.model == nil)
                }
            }
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var model: WorkspaceModel?
    private var splash: NSWindow?
    private var mainWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private let startup = StartupState()
    private let session = AnalysisSession()
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        do { try Theme.registerFonts() }
        catch { startup.error = error.localizedDescription; startup.checking = false }
        let available = NSScreen.main?.visibleFrame.size ?? Theme.splashSize
        let splashSize = NSSize(width: min(Theme.splashSize.width, available.width - 40), height: min(Theme.splashSize.height, available.height - 40))
        let splash = NSWindow(contentRect: NSRect(origin: .zero, size: splashSize), styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
        splash.title = "Endpoint Mapper"
        splash.titleVisibility = .hidden
        splash.titlebarAppearsTransparent = true
        splash.backgroundColor = NSColor(Theme.brandBackground)
        splash.isReleasedWhenClosed = false
        let splashContent = NSHostingController(rootView: SplashView(state: startup, retry: { [weak self] in self?.bootstrap() }))
        splashContent.sizingOptions = []
        splash.contentViewController = splashContent
        splash.setContentSize(splashSize)
        splash.center()
        splash.makeKeyAndOrderFront(nil)
        self.splash = splash
        NSApp.activate(ignoringOtherApps: true)
        if startup.error == nil { bootstrap() }
    }
    private func bootstrap() {
        startup.error = nil
        startup.checking = true
        Task {
            do {
                try Theme.registerFonts()
                let status = try await session.start()
                let model = WorkspaceModel(engine: status, session: session)
                self.model = model
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 760), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
                window.title = "Endpoint Mapper"
                window.titlebarAppearsTransparent = true
                window.minSize = NSSize(width: 960, height: 600)
                window.isReleasedWhenClosed = false
                let content = NSHostingController(rootView: GeometryReader { geometry in
                    WorkspaceView(model: model)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                })
                content.sizingOptions = []
                window.contentViewController = content
                window.setContentSize(NSSize(width: 1200, height: 760))
                window.center()
                mainWindow = window
                splash?.orderOut(nil)
                splash = nil
                window.makeKeyAndOrderFront(nil)
            } catch {
                startup.checking = false
                startup.error = "Não foi possível iniciar: \(error.localizedDescription)"
            }
        }
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task {
            await session.stop()
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
    func showAbout() {
        if aboutWindow == nil {
            let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Sobre Endpoint Mapper"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: AboutView())
            window.center()
            aboutWindow = window
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { (mainWindow ?? splash)?.makeKeyAndOrderFront(nil) }
        return true
    }
}
