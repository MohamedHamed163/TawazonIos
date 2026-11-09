//
//  StompClient.swift
//  tawazon
//
//  Minimal STOMP 1.2 client over a raw WebSocket (SockJS `/ws/websocket` endpoint).
//  Used for real-time chat: message delivery, typing indicators, and read receipts.
//

import Foundation

struct StompFrame {
    let command: String
    let headers: [String: String]
    let body: String
}

@MainActor
final class StompClient {
    enum State { case disconnected, connecting, connected }

    private let url: URL
    private let token: String
    private var task: URLSessionWebSocketTask?
    private(set) var state: State = .disconnected

    private struct Subscription {
        let id: String
        let destination: String
        let handler: (StompFrame) -> Void
    }
    private var subscriptions: [String: Subscription] = [:]
    private var subCounter = 0
    private var shouldReconnect = false
    private var reconnectAttempts = 0
    private var heartbeatTask: Task<Void, Never>?

    /// Invoked each time the STOMP session reaches the CONNECTED state (including after a reconnect).
    var onConnect: (() -> Void)?

    init(url: URL, token: String) {
        self.url = url
        self.token = token
    }

    // MARK: - Lifecycle

    func connect() {
        guard state == .disconnected else { return }
        shouldReconnect = true
        openSocket()
    }

    func disconnect() {
        shouldReconnect = false
        heartbeatTask?.cancel()
        heartbeatTask = nil
        if state == .connected {
            rawSend("DISCONNECT\n\n\u{00}")
        }
        state = .disconnected
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    private func openSocket() {
        state = .connecting
        let socket = URLSession.shared.webSocketTask(with: url)
        task = socket
        socket.resume()
        receiveLoop()
        sendConnectFrame()
    }

    private func sendConnectFrame() {
        let frame = "CONNECT\naccept-version:1.2\nheart-beat:10000,10000\nAuthorization:Bearer \(token)\n\n\u{00}"
        rawSend(frame)
    }

    // MARK: - Subscriptions & sending

    @discardableResult
    func subscribe(_ destination: String, handler: @escaping (StompFrame) -> Void) -> String {
        subCounter += 1
        let id = "sub-\(subCounter)"
        let sub = Subscription(id: id, destination: destination, handler: handler)
        subscriptions[id] = sub
        if state == .connected { sendSubscribeFrame(sub) }
        return id
    }

    private func sendSubscribeFrame(_ sub: Subscription) {
        rawSend("SUBSCRIBE\nid:\(sub.id)\ndestination:\(sub.destination)\n\n\u{00}")
    }

    /// Sends a STOMP SEND frame. `body` should be a JSON string (or empty for header-only signals).
    func send(destination: String, body: String = "") {
        var frame = "SEND\ndestination:\(destination)\n"
        if !body.isEmpty {
            frame += "content-type:application/json\ncontent-length:\(body.utf8.count)\n"
        }
        frame += "\n\(body)\u{00}"
        rawSend(frame)
    }

    private func rawSend(_ text: String) {
        task?.send(.string(text)) { _ in }
    }

    // MARK: - Receiving

    private func receiveLoop() {
        task?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text): self.handleIncoming(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) { self.handleIncoming(text) }
                    @unknown default: break
                    }
                    self.receiveLoop()
                case .failure:
                    self.handleSocketClosed()
                }
            }
        }
    }

    private func handleIncoming(_ text: String) {
        // A WebSocket message may carry one or more NUL-terminated STOMP frames,
        // plus bare newlines used as heartbeats.
        for raw in text.components(separatedBy: "\u{00}") {
            let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\n"))
            guard !trimmed.isEmpty, let frame = parseFrame(trimmed) else { continue }
            dispatch(frame)
        }
    }

    private func parseFrame(_ raw: String) -> StompFrame? {
        let headerBodySplit = raw.range(of: "\n\n")
        let headerPart: String
        let body: String
        if let headerBodySplit {
            headerPart = String(raw[raw.startIndex..<headerBodySplit.lowerBound])
            body = String(raw[headerBodySplit.upperBound...])
        } else {
            headerPart = raw
            body = ""
        }
        var lines = headerPart.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard !lines.isEmpty else { return nil }
        let command = lines.removeFirst()
        var headers: [String: String] = [:]
        for line in lines {
            guard let idx = line.firstIndex(of: ":") else { continue }
            headers[String(line[line.startIndex..<idx])] = String(line[line.index(after: idx)...])
        }
        return StompFrame(command: command, headers: headers, body: body)
    }

    private func dispatch(_ frame: StompFrame) {
        switch frame.command {
        case "CONNECTED":
            state = .connected
            reconnectAttempts = 0
            for sub in subscriptions.values { sendSubscribeFrame(sub) }
            startHeartbeat()
            onConnect?()
        case "MESSAGE":
            if let subId = frame.headers["subscription"], let sub = subscriptions[subId] {
                sub.handler(frame)
            }
        default:
            break
        }
    }

    private func handleSocketClosed() {
        guard state != .disconnected else { return }
        state = .disconnected
        heartbeatTask?.cancel()
        task = nil
        guard shouldReconnect else { return }
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 20.0)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, self.shouldReconnect, self.state == .disconnected else { return }
            self.openSocket()
        }
    }

    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                guard let self, self.state == .connected else { break }
                self.rawSend("\n")
            }
        }
    }
}
