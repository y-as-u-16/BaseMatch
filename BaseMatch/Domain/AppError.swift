import Foundation

enum AppError: LocalizedError, Equatable {
    case validation(String)
    case notFound(String)
    case database(String)

    var errorDescription: String? {
        switch self {
        case let .validation(message), let .notFound(message), let .database(message):
            message
        }
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// 空文字は永続化せず nil に寄せる（移行元の正規化と同じ）。
    var normalizedOptional: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}
