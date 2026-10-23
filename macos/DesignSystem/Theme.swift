import SwiftUI
import AppKit
import CoreText

enum Theme {
    static let background = Color(hex: 0x0D1117)
    static let brandBackground = Color(hex: 0x100609)
    static let splashSize = NSSize(width: 1320, height: 840)
    static let panel = Color(hex: 0x161B22)
    static let border = Color(hex: 0x30363D)
    static let text = Color(hex: 0xE6EDF3)
    static let secondary = Color(hex: 0x8B949E)
    static let red = Color(hex: 0xF73346)
    static let yellow = Color(hex: 0xFDDF33)
    static func font(_ size: CGFloat = 13, weight: String = "Regular") -> Font {
        .custom("JetBrainsMono-\(weight)", size: size)
    }
    static func registerFonts(in bundle: Bundle = .main) throws {
        for weight in ["Regular", "Medium", "SemiBold", "Bold"] {
            guard let url = bundle.url(forResource: "JetBrainsMono-\(weight)", withExtension: "ttf", subdirectory: "Fonts") else {
                throw BootstrapError.message("Fonte JetBrains Mono ausente no aplicativo.")
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            guard NSFont(name: "JetBrainsMono-\(weight)", size: 13) != nil else {
                throw BootstrapError.message("Não foi possível registrar JetBrains Mono \(weight).")
            }
        }
    }
    static var logo: NSImage? {
        Bundle.main.url(forResource: "logo", withExtension: "png", subdirectory: "Branding").flatMap(NSImage.init(contentsOf:))
    }
}
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255, opacity: 1)
    }
}
enum BootstrapError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case let .message(message) = self { return message }; return nil }
}

/// Shared suite wordmark; the original logo remains an unmodified resource.
struct BrandWordmark: View {
    var size: CGFloat = 26
    var body: some View {
        (Text("Endpoint").foregroundColor(Theme.yellow) + Text("Mapper").foregroundColor(Theme.red))
            .font(Theme.font(size, weight: "Bold"))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityLabel("Endpoint Mapper")
    }
}
