import Foundation

final class APIClient {
    static let shared = APIClient()

    let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var isRefreshing = false

    private init() {
        self.baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? "https://api.elite.dating"
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        _ method: HTTPMethod,
        path: String,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let data = try await rawRequest(method, path: path, body: body, queryItems: queryItems, requiresAuth: requiresAuth)
        return try decoder.decode(T.self, from: data)
    }

    func requestVoid(
        _ method: HTTPMethod,
        path: String,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        _ = try await rawRequest(method, path: path, body: body, requiresAuth: requiresAuth)
    }

    // MARK: - Multipart Upload

    func uploadPhoto(data photoData: Data, filename: String = "photo.jpg") async throws -> PhotoUploadResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/photos/upload") else {
            throw APIError.serverError("Invalid URL")
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(photoData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (responseData, response) = try await session.data(for: request)
        try validateResponse(response, data: responseData)
        return try decoder.decode(PhotoUploadResponse.self, from: responseData)
    }

    // MARK: - Private

    private func rawRequest(
        _ method: HTTPMethod,
        path: String,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> Data {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.serverError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            guard let token = TokenManager.shared.accessToken else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)

        // Handle 401 - try token refresh
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401, requiresAuth {
            if try await refreshAccessToken() {
                // Retry with new token
                request.setValue("Bearer \(TokenManager.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await session.data(for: request)
                try validateResponse(retryResponse, data: retryData)
                return retryData
            }
            throw APIError.unauthorized
        }

        try validateResponse(response, data: data)
        return data
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkUnavailable
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.serverError("Request failed with status \(httpResponse.statusCode)")
        }
    }

    private func refreshAccessToken() async throws -> Bool {
        guard !isRefreshing, let refreshToken = TokenManager.shared.refreshToken else {
            return false
        }
        isRefreshing = true
        defer { isRefreshing = false }

        let body = ["refresh_token": refreshToken]
        let bodyData = try encoder.encode(body)

        guard let url = URL(string: "\(baseURL)/api/v1/auth/refresh") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            TokenManager.shared.clearTokens()
            return false
        }

        let tokenResponse = try decoder.decode(TokenRefreshResponse.self, from: data)
        TokenManager.shared.accessToken = tokenResponse.accessToken
        return true
    }

    // MARK: - Types

    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE, PATCH
    }
}

// MARK: - Response Types

struct ErrorResponse: Codable {
    let message: String
}

struct PhotoUploadResponse: Codable {
    let url: String
}

struct TokenRefreshResponse: Codable {
    let accessToken: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

// MARK: - AnyEncodable Wrapper

private struct AnyEncodable: Encodable {
    let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
