import Foundation

/// Единый тип ошибок для UI. Сетевые/AI-ошибки маппятся сюда в сервисном слое.
enum AppError: Error, Equatable, Sendable {
    case network
    case timeout
    case server(statusCode: Int)
    case decoding
    case emptyResponse
    case recognitionFailed
    case noFoodsFound
    case cameraUnavailable
    case unknown

    var title: String {
        switch self {
        case .network, .timeout: L10n.Error.networkTitle
        case .recognitionFailed, .noFoodsFound, .decoding, .emptyResponse: L10n.Error.recognitionTitle
        case .cameraUnavailable: L10n.Error.cameraTitle
        case .server, .unknown: L10n.Error.genericTitle
        }
    }

    var message: String {
        switch self {
        case .network: L10n.Error.networkMessage
        case .timeout: L10n.Error.timeoutMessage
        case .noFoodsFound: L10n.Error.noFoodsMessage
        case .recognitionFailed, .decoding, .emptyResponse: L10n.Error.recognitionMessage
        case .cameraUnavailable: L10n.Error.cameraMessage
        case .server, .unknown: L10n.Error.genericMessage
        }
    }

    var systemImage: String {
        switch self {
        case .network, .timeout: "wifi.slash"
        case .recognitionFailed, .noFoodsFound, .decoding, .emptyResponse: "eye.trianglebadge.exclamationmark"
        case .cameraUnavailable: "camera.badge.ellipsis"
        case .server, .unknown: "exclamationmark.triangle"
        }
    }

    /// Можно ли надеяться на успех при повторе.
    var isRetryable: Bool {
        switch self {
        case .network, .timeout: true
        case .server(let code): code >= 500 || code == 429
        default: false
        }
    }

    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        if error is DecodingError { return .decoding }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut: return .timeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
                 .cannotFindHost, .dataNotAllowed, .internationalRoamingOff:
                return .network
            default: return .network
            }
        }
        return .unknown
    }
}
