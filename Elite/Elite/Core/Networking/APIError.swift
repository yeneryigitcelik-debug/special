import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case serverError(String)
    case networkUnavailable
    case decodingError
    case invalidReferralCode
    case referralCodeExpired
    case referralCodeUsed
    case profileNotFound
    case matchNotFound
    case messageSendFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let message):
            return message
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        case .decodingError:
            return "Something went wrong. Please try again."
        case .invalidReferralCode:
            return "This invitation code is not valid."
        case .referralCodeExpired:
            return "This invitation code has expired."
        case .referralCodeUsed:
            return "This invitation code has already been used."
        case .profileNotFound:
            return "Profile not found."
        case .matchNotFound:
            return "Match not found."
        case .messageSendFailed:
            return "Failed to send message. Please try again."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
