import SwiftUI

@MainActor final class StartupState: ObservableObject {
    @Published var error: String?
    @Published var checking = true
}
struct SplashView: View {
    @ObservedObject var state: StartupState
    let retry: () -> Void
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 18) {
                if let logo = Theme.logo {
                    Image(nsImage: logo).resizable().scaledToFit()
                        .frame(width: min(350, geometry.size.height * 0.44), height: min(350, geometry.size.height * 0.44))
                        .accessibilityLabel("Endpoint Mapper, morcego vermelho com setas amarelas")
                }
                BrandWordmark()
                if state.checking {
                    Label("Iniciando…", systemImage: "waveform.path")
                        .font(Theme.font(11)).foregroundStyle(Theme.secondary)
                        .padding(.top, 4)
                }
                if let error = state.error {
                    Text(error).multilineTextAlignment(.center).foregroundStyle(Theme.yellow)
                        .frame(maxWidth: 480)
                    HStack {
                        Button(action: retry) { Label("Tentar novamente", systemImage: "arrow.clockwise") }
                        Button { NSApp.terminate(nil) } label: { Label("Encerrar", systemImage: "xmark") }
                    }
                }
            }
            .font(Theme.font()).foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.brandBackground).preferredColorScheme(.dark)
    }
}
struct PreferencesView: View {
    @AppStorage("textScale") private var textScale = 1.0
    @AppStorage("analysisTimeout") private var analysisTimeout = 120.0
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label("Preferências", systemImage: "gearshape").font(Theme.font(22, weight: "Bold"))
            Label("Tamanho do texto de navegação", systemImage: "textformat.size")
            Picker("Escala", selection: $textScale) {
                Text("Padrão").tag(1.0)
                Text("Ampliado").tag(1.15)
                Text("Grande").tag(1.3)
            }.pickerStyle(.segmented)
            Picker(selection: $analysisTimeout) {
                Text("30 segundos").tag(30.0)
                Text("2 minutos").tag(120.0)
                Text("5 minutos").tag(300.0)
            } label: { Label("Prazo do inventário", systemImage: "clock") }
            Label("Privacidade", systemImage: "lock.shield")
            Text("Sem telemetria, contas ou comunicação de rede.\nProjetos são acessados somente após sua seleção.").foregroundStyle(Theme.secondary)
        }.padding(28).frame(width: 470).font(Theme.font()).foregroundStyle(Theme.text)
            .background(Theme.background).preferredColorScheme(.dark)
    }
}
struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            if let logo = Theme.logo { Image(nsImage: logo).resizable().scaledToFit().frame(width: 140, height: 140) }
            Text("Endpoint Mapper").font(Theme.font(22, weight: "Bold"))
            Text("Versão 0.2.0 • Build 3")
            Text("Fundação nativa • macOS 14+\nSwiftUI + AppKit + Node.js").multilineTextAlignment(.center).foregroundStyle(Theme.secondary)
            Button { if let url = Bundle.main.url(forResource: "OFL", withExtension: "txt", subdirectory: "Fonts") { NSWorkspace.shared.open(url) } } label: {
                Label("Licença JetBrains Mono", systemImage: "doc.text")
            }
            Button { if let url = Bundle.main.url(forResource: "Node-LICENSE", withExtension: "txt") { NSWorkspace.shared.open(url) } } label: {
                Label("Licença Node.js", systemImage: "doc.text")
            }
            Button { if let url = Bundle.main.url(forResource: "LICENSE-MIT", withExtension: nil, subdirectory: "engine/node_modules/ignore") { NSWorkspace.shared.open(url) } } label: {
                Label("Licença ignore (MIT)", systemImage: "doc.text")
            }
        }.padding(28).frame(width: 440).font(Theme.font()).foregroundStyle(Theme.text).background(Theme.background).preferredColorScheme(.dark)
    }
}
