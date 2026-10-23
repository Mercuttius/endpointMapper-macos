import Foundation

indirect enum RPCValue: Codable, Sendable, Equatable {
    case object([String: RPCValue]), array([RPCValue]), string(String), number(Double), bool(Bool), null
    init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        if box.decodeNil() { self = .null }
        else if let value = try? box.decode(Bool.self) { self = .bool(value) }
        else if let value = try? box.decode(String.self) { self = .string(value) }
        else if let value = try? box.decode(Double.self) { self = .number(value) }
        else if let value = try? box.decode([String: RPCValue].self) { self = .object(value) }
        else { self = .array(try box.decode([RPCValue].self)) }
    }
    func encode(to encoder: Encoder) throws {
        var box = encoder.singleValueContainer()
        switch self {
        case .object(let value): try box.encode(value)
        case .array(let value): try box.encode(value)
        case .string(let value): try box.encode(value)
        case .number(let value): try box.encode(value)
        case .bool(let value): try box.encode(value)
        case .null: try box.encodeNil()
        }
    }
    subscript(_ key: String) -> RPCValue? { if case .object(let value) = self { return value[key] }; return nil }
    var string: String? { if case .string(let value) = self { return value }; return nil }
    var number: Double? { if case .number(let value) = self { return value }; return nil }
    func decode<T: Decodable>(_ type: T.Type) throws -> T { try JSONDecoder().decode(type, from: JSONEncoder().encode(self)) }
}

enum SessionError: LocalizedError, Sendable {
    case disconnected, malformed, frameTooLarge, timeout, cancelled, overloaded
    case remote(Int, String)
    var errorDescription: String? {
        switch self {
        case .disconnected: return "O motor local foi desconectado. Reconecte para continuar."
        case .malformed: return "O motor enviou uma mensagem inválida."
        case .frameTooLarge: return "Uma mensagem do motor excedeu o limite permitido."
        case .timeout: return "O motor não respondeu dentro do prazo. Reconecte para tentar novamente."
        case .cancelled: return "Inventário cancelado."
        case .overloaded: return "Há requisições demais em andamento."
        case let .remote(code, message): return "Motor local (\(code)): \(message)"
        }
    }
}

struct Inventory: Decodable, Sendable {
    let files: Int
    let directories: Int
    let ignored: Int
    let symlinks: Int
    let languages: [String: Int]
    let warnings: [String]
    let truncated: Bool
}
