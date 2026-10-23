import AppKit
import Foundation
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let image = NSBitmapImageRep(data: try Data(contentsOf: url))!
var red: [String: Int] = [:], yellow: [String: Int] = [:]
for y in 0..<image.pixelsHigh {
    for x in 0..<image.pixelsWide {
        guard let c = image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
        let r = Int((c.redComponent * 255).rounded()), g = Int((c.greenComponent * 255).rounded()), b = Int((c.blueComponent * 255).rounded())
        let hex = String(format: "#%02X%02X%02X", r, g, b)
        if r > 180 && g < 90 && b < 120 { red[hex, default: 0] += 1 }
        if r > 180 && g > 180 && b < 100 { yellow[hex, default: 0] += 1 }
    }
}
func dominant(_ counts: [String: Int]) -> String {
    counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.first!.key
}
print("{\"batRed\":\"\(dominant(red))\",\"arrowYellow\":\"\(dominant(yellow))\",\"method\":\"most frequent sRGB pixel within red/yellow masks\"}")
