import Foundation

@MainActor
final class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var messageHandlers: [UUID: (Message) -> Void] = [:]
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var subscribedMatchIds: Set<UUID> = []

    private init() {
        self.session = URLSession(configuration: .default)
    }

    // MARK: - Connection

    func connect() {
        guard let token = TokenManager.shared.accessToken else { return }

        let baseURL = APIClient.shared.baseURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")

        guard let url = URL(string: "\(baseURL)/ws?token=\(token)") else { return }

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        reconnectAttempts = 0
        receiveMessages()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        subscribedMatchIds.removeAll()
        messageHandlers.removeAll()
    }

    // MARK: - Subscribe to Match

    func subscribe(matchId: UUID, onMessage: @escaping (Message) -> Void) {
        messageHandlers[matchId] = onMessage
        subscribedMatchIds.insert(matchId)

        let payload: [String: String] = [
            "type": "subscribe",
            "match_id": matchId.uuidString
        ]

        sendJSON(payload)
    }

    func unsubscribe(matchId: UUID) {
        messageHandlers.removeValue(forKey: matchId)
        subscribedMatchIds.remove(matchId)

        let payload: [String: String] = [
            "type": "unsubscribe",
            "match_id": matchId.uuidString
        ]

        sendJSON(payload)
    }

    // MARK: - Receive

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleIncomingMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleIncomingMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    self.receiveMessages()

                case .failure:
                    self.isConnected = false
                    self.attemptReconnect()
                }
            }
        }
    }

    private func handleIncomingMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // Parse wrapper
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "new_message":
            guard let messageData = try? JSONSerialization.data(withJSONObject: json["message"] ?? [:]),
                  let message = try? decoder.decode(Message.self, from: messageData) else { return }

            messageHandlers[message.matchId]?(message)

        case "pong":
            break

        default:
            break
        }
    }

    // MARK: - Send

    private func sendJSON(_ payload: [String: String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(text)) { _ in }
    }

    // MARK: - Reconnect

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else { return }
        reconnectAttempts += 1

        let delay = pow(2.0, Double(reconnectAttempts))
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.connect()

            // Resubscribe to rooms
            for matchId in self.subscribedMatchIds {
                let payload: [String: String] = [
                    "type": "subscribe",
                    "match_id": matchId.uuidString
                ]
                self.sendJSON(payload)
            }
        }
    }

    // MARK: - Ping

    func startPing() {
        Task {
            while isConnected {
                try? await Task.sleep(for: .seconds(30))
                sendJSON(["type": "ping"])
            }
        }
    }
}
