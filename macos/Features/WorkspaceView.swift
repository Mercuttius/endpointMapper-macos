import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var model: WorkspaceModel
    @AppStorage("textScale") private var textScale = 1.0
    private let sections = [("Projeto", "folder"), ("Endpoints", "point.3.connected.trianglepath.dotted"), ("Mapa", "point.topleft.down.curvedto.point.bottomright.up"), ("Diagnósticos", "exclamationmark.triangle")]
    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 2) {
                    if let logo = Theme.logo {
                        Image(nsImage: logo).resizable().scaledToFit()
                            .frame(width: 56, height: 56).accessibilityHidden(true)
                    }
                    BrandWordmark(size: 18)
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                Text("EXPLORAR").font(Theme.font(10, weight: "SemiBold")).foregroundStyle(Theme.secondary)
                ForEach(sections, id: \.0) { title, symbol in
                    Button { model.section = title } label: {
                        Label(title, systemImage: symbol).frame(maxWidth: .infinity, alignment: .leading).padding(9)
                            .background(model.section == title ? Theme.red.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 6))
                    }.buttonStyle(.plain).foregroundStyle(model.section == title ? Theme.red : Theme.text)
                }
                Spacer()
                Label("100% local", systemImage: "lock.shield").foregroundStyle(Theme.secondary)
                Text("Fundação • v0.2.0").font(Theme.font(11)).foregroundStyle(Theme.secondary)
            }.padding(16).background(Theme.brandBackground)
            .frame(minWidth: 250, idealWidth: 260, maxWidth: 300, maxHeight: .infinity).background(Theme.brandBackground)

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(model.project?.lastPathComponent ?? "Explore suas APIs").font(Theme.font(25, weight: "Bold"))
                        Text(model.project == nil ? "Selecione um projeto backend para começar." : model.project!.path)
                            .foregroundStyle(Theme.secondary).textSelection(.enabled)
                    }
                    Spacer()
                }
                if model.section == "Projeto" {
                    projectContent
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: sections.first(where: { $0.0 == model.section })!.1).font(.system(size: 32)).foregroundStyle(Theme.yellow)
                        Text("\(model.section): próxima etapa").font(Theme.font(18, weight: "SemiBold"))
                        Text("Esta versão valida a aplicação nativa e o motor local.\nA análise estática ainda não está implementada.")
                            .multilineTextAlignment(.center).foregroundStyle(Theme.secondary)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Spacer(minLength: 0)
                HStack {
                    Label(model.connected ? "Motor local conectado" : "Motor desconectado", systemImage: model.connected ? "checkmark.circle" : "exclamationmark.triangle")
                    Spacer()
                    Text("Node \(model.engine.runtime)")
                }.foregroundStyle(Theme.secondary).font(Theme.font(11))
            }.padding(28).background(Theme.background)
            .frame(minWidth: 420, idealWidth: 650, maxWidth: .infinity, maxHeight: .infinity).background(Theme.background)

            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Inspector", systemImage: "sidebar.right").font(Theme.font(15, weight: "SemiBold"))
                Divider()
                Text("PROJETO").foregroundStyle(Theme.secondary)
                Text(model.project?.lastPathComponent ?? "Nenhuma pasta selecionada").textSelection(.enabled)
                Text("ANÁLISE").foregroundStyle(Theme.secondary)
                Text("Endpoints: não realizada")
                if let inventory = model.inventory {
                    Text("Inventário: \(inventory.files) arquivos")
                    Text("\(inventory.directories) pastas • \(inventory.ignored) exclusões • \(inventory.symlinks) links omitidos").foregroundStyle(Theme.secondary)
                    ForEach(inventory.languages.keys.sorted(), id: \.self) { language in
                        Text("\(language): \(inventory.languages[language] ?? 0) arquivos")
                    }
                }
                Text("Frameworks suportados: nenhum nesta versão.").foregroundStyle(Theme.secondary)
                Divider()
                Label("Arquivos preservados", systemImage: "lock.doc")
                Text("Selecionar uma pasta não executa nem modifica seus arquivos.").foregroundStyle(Theme.secondary)
                Spacer()
            }.padding(20).frame(maxWidth: .infinity, alignment: .topLeading)
            }.background(Theme.panel)
            .frame(minWidth: 230, idealWidth: 260, maxWidth: 330, maxHeight: .infinity).background(Theme.panel)
        }
        .font(Theme.font(13 * textScale)).foregroundStyle(Theme.text).tint(Theme.red).preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup {
                Button { model.openProject() } label: { Label("Abrir projeto", systemImage: "folder.badge.plus") }.help("Abrir projeto (⌘O)")
                Button { model.closeProject() } label: { Label("Fechar projeto", systemImage: "xmark.circle") }.disabled(model.project == nil)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard urls.count == 1, let url = urls.first else { return false }
            model.select(url)
            return model.issue == nil
        }
        .alert("Não foi possível abrir o projeto", isPresented: Binding(get: { model.issue != nil }, set: { if !$0 { model.issue = nil } })) {
            Button("OK") { model.issue = nil }
        } message: { Text(model.issue ?? "") }
    }
    private var projectContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(model.project == nil ? "Seu código permanece no seu Mac" : "Projeto selecionado", systemImage: "folder.badge.gearshape")
                .font(Theme.font(17, weight: "SemiBold"))
            Text("Faça um inventário dos arquivos do projeto sem executar seu código. A identificação de linguagens por extensão não significa suporte à análise de endpoints.")
                .foregroundStyle(Theme.secondary).fixedSize(horizontal: false, vertical: true)
            Button { model.openProject() } label: { Label(model.project == nil ? "Abrir projeto" : "Escolher outra pasta", systemImage: "folder.badge.plus") }
                .buttonStyle(.borderedProminent).tint(Theme.red).foregroundStyle(.black)
            if model.project != nil {
                HStack {
                    Button { model.startScan() } label: { Label("Inventariar arquivos", systemImage: "magnifyingglass") }
                        .disabled(!model.connected || model.scanning)
                    if model.scanning {
                        Button { model.cancelScan() } label: { Label("Cancelar", systemImage: "stop.circle") }
                        ProgressView().controlSize(.small)
                    }
                }
                Text("Arquivos identificados: \(model.filesSeen)").foregroundStyle(Theme.secondary)
            }
            if !model.connected {
                Button { model.reconnect() } label: { Label(model.reconnecting ? "Reconectando…" : "Reconectar motor", systemImage: "arrow.clockwise") }
                    .disabled(model.reconnecting)
            }
            if let message = model.scanMessage { Text(message).foregroundStyle(Theme.yellow) }
            if let inventory = model.inventory, !inventory.warnings.isEmpty {
                Text(inventory.warnings.joined(separator: "\n")).foregroundStyle(Theme.yellow)
                    .lineLimit(5).help(inventory.warnings.joined(separator: "\n"))
            }
            if !model.recentPaths.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(model.recentPaths.enumerated()), id: \.offset) { _, path in
                            Text(path).font(Theme.font(11)).textSelection(.enabled)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxHeight: 150)
                Text("Últimos caminhos recebidos • até 100 itens").font(Theme.font(10)).foregroundStyle(Theme.secondary)
            }
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
    }
}
