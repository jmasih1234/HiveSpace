import Foundation

// MARK: - API Configuration

enum APIConfig {
    // Change this to your production server URL when deploying
    static let baseURL = "https://api.hivespace.app/v1"
    static let timeout: TimeInterval = 30
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case serverError(Int, String?)
    case unauthorized
    case offline
    case rateLimited
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request URL."
        case .noData: return "No data received from server."
        case .decodingFailed: return "Failed to process server response."
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg ?? "Unknown")"
        case .unauthorized: return "Session expired. Please sign in again."
        case .offline: return "No internet connection."
        case .rateLimited: return "Too many requests. Please wait a moment."
        case .unknown(let err): return err.localizedDescription
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Endpoint

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let requiresAuth: Bool

    // Auth
    static let signIn = APIEndpoint(path: "/auth/sign-in", method: .post, requiresAuth: false)
    static let signUp = APIEndpoint(path: "/auth/sign-up", method: .post, requiresAuth: false)
    static let refreshToken = APIEndpoint(path: "/auth/refresh", method: .post, requiresAuth: false)

    // Colonies
    static let colonies = APIEndpoint(path: "/colonies", method: .get, requiresAuth: true)
    static let createColony = APIEndpoint(path: "/colonies", method: .post, requiresAuth: true)
    static func colony(_ id: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(id.uuidString)", method: .get, requiresAuth: true)
    }
    static func joinColony(_ code: String) -> APIEndpoint {
        APIEndpoint(path: "/colonies/join/\(code)", method: .post, requiresAuth: true)
    }

    // Tasks
    static func tasks(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/tasks", method: .get, requiresAuth: true)
    }
    static func createTask(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/tasks", method: .post, requiresAuth: true)
    }
    static func updateTask(colonyID: UUID, taskID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/tasks/\(taskID.uuidString)", method: .put, requiresAuth: true)
    }
    static func deleteTask(colonyID: UUID, taskID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/tasks/\(taskID.uuidString)", method: .delete, requiresAuth: true)
    }

    // Expenses
    static func expenses(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/expenses", method: .get, requiresAuth: true)
    }
    static func createExpense(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/expenses", method: .post, requiresAuth: true)
    }
    static func settleExpense(colonyID: UUID, expenseID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/expenses/\(expenseID.uuidString)/settle", method: .post, requiresAuth: true)
    }

    // Messages
    static func channels(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/channels", method: .get, requiresAuth: true)
    }
    static func messages(channelID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/channels/\(channelID.uuidString)/messages", method: .get, requiresAuth: true)
    }
    static func sendMessage(channelID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/channels/\(channelID.uuidString)/messages", method: .post, requiresAuth: true)
    }

    // Trips
    static func trips(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/trips", method: .get, requiresAuth: true)
    }
    static func createTrip(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/trips", method: .post, requiresAuth: true)
    }

    // Availability
    static func availabilityPolls(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/availability", method: .get, requiresAuth: true)
    }

    // Activity Feed
    static func activityFeed(colonyID: UUID) -> APIEndpoint {
        APIEndpoint(path: "/colonies/\(colonyID.uuidString)/activity", method: .get, requiresAuth: true)
    }

    // Profile
    static let profile = APIEndpoint(path: "/me", method: .get, requiresAuth: true)
    static let updateProfile = APIEndpoint(path: "/me", method: .put, requiresAuth: true)
}

// MARK: - Network Service Protocol

protocol NetworkServiceProtocol: Sendable {
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?
    ) async throws -> T
}

// MARK: - Live Network Service

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    static let shared = NetworkService()

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "hivespace_auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "hivespace_auth_token") }
    }

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeout
        config.waitsForConnectivity = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func setAuthToken(_ token: String?) {
        authToken = token
    }

    func request<T: Decodable>(
        endpoint: APIEndpoint,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard var components = URLComponents(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        case 401:
            throw NetworkError.unauthorized
        case 429:
            throw NetworkError.rateLimited
        default:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(httpResponse.statusCode, message)
        }
    }
}

// MARK: - Mock Network Service (for offline/demo mode)

final class MockNetworkService: NetworkServiceProtocol {
    static let shared = MockNetworkService()

    func request<T: Decodable>(
        endpoint: APIEndpoint,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?
    ) async throws -> T {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(300))

        // Return empty responses for now - the app falls back to local data
        throw NetworkError.offline
    }
}

// MARK: - Type Erasure Helper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - API Response Wrappers

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

struct AuthResponse: Codable {
    let token: String
    let refreshToken: String
    let user: HSUser
    let expiresAt: Date
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let displayName: String
    let username: String
}
