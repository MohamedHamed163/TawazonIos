//
//  ChatViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class ConversationsViewModel {
    private let api = APIService.shared

    var conversations: [UserConversationDTO] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            conversations = try await api.getMyConversations(page: 0, size: 50, token: token).content
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class ChatViewModel {
    private let api = APIService.shared
    private let uploads = FileUploadManager.shared
    private var stomp: StompClient?

    private(set) var conversationId: String?
    private let coachProfileId: String?
    var messages: [MessageDTO] = []
    var draft = ""
    var isLoading = false
    var isSending = false
    var errorMessage: String?
    var isOtherTyping = false

    private var typingResetTask: Task<Void, Never>?
    private var lastTypingSentAt: Date = .distantPast

    init(conversationId: String) {
        self.conversationId = conversationId
        self.coachProfileId = nil
    }

    /// Starts (or fetches the existing) conversation with the coach on first load.
    init(coachProfileId: String) {
        self.conversationId = nil
        self.coachProfileId = coachProfileId
    }

    func load() async {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let id = try await resolveConversationId(token: token)
            // API returns newest-first; reverse for chronological display.
            let page = try await api.getMessages(conversationId: id, page: 0, size: 50, token: token)
            messages = page.content.reversed()
            connectRealtime(conversationId: id, token: token)
            try? await api.markConversationRead(conversationId: id, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Tears down the realtime connection; call when leaving the chat screen.
    func disconnect() {
        stomp?.disconnect()
        stomp = nil
        typingResetTask?.cancel()
        typingResetTask = nil
    }

    // MARK: - Realtime

    private func connectRealtime(conversationId id: String, token: String) {
        guard stomp == nil, let wsURL = api.webSocketURL else { return }
        let client = StompClient(url: wsURL, token: token)
        client.onConnect = { [weak self, weak client] in
            guard let self, let client else { return }
            client.subscribe("/user/queue/messages") { [weak self] frame in
                self?.handleIncomingMessage(frame)
            }
            client.subscribe("/user/queue/typing") { [weak self] frame in
                self?.handleTypingEvent(frame)
            }
            client.subscribe("/user/queue/read-receipt") { [weak self] frame in
                self?.handleReadReceipt(frame)
            }
            client.send(destination: "/app/chat.read.\(id)")
        }
        stomp = client
        client.connect()
    }

    private func handleIncomingMessage(_ frame: StompFrame) {
        guard let data = frame.body.data(using: .utf8),
              let msg = try? JSONDecoder().decode(MessageDTO.self, from: data),
              msg.conversationId == conversationId else { return }
        if !messages.contains(where: { $0.id == msg.id }) {
            messages.append(msg)
        }
        // An inbound message from the coach is immediately read while the chat is open.
        if msg.senderType.uppercased() != "SUBSCRIBER", let id = conversationId {
            stomp?.send(destination: "/app/chat.read.\(id)")
        }
    }

    private func handleTypingEvent(_ frame: StompFrame) {
        guard let data = frame.body.data(using: .utf8),
              let evt = try? JSONDecoder().decode(TypingEventDTO.self, from: data),
              evt.conversationId == conversationId else { return }
        isOtherTyping = true
        typingResetTask?.cancel()
        typingResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self?.isOtherTyping = false
        }
    }

    private func handleReadReceipt(_ frame: StompFrame) {
        guard let data = frame.body.data(using: .utf8),
              let evt = try? JSONDecoder().decode(ReadReceiptEventDTO.self, from: data),
              evt.conversationId == conversationId else { return }
        let now = ISO8601DateFormatter().string(from: Date())
        messages = messages.map { m in
            guard m.readAt == nil, m.senderType.uppercased() == "SUBSCRIBER" else { return m }
            return MessageDTO(
                id: m.id,
                conversationId: m.conversationId,
                senderId: m.senderId,
                senderType: m.senderType,
                content: m.content,
                attachments: m.attachments,
                sentAt: m.sentAt,
                readAt: now
            )
        }
    }

    /// Notifies the coach that the user is typing (throttled to one signal every 2s).
    func userIsTyping() {
        guard let id = conversationId, let stomp, stomp.state == .connected else { return }
        let now = Date()
        guard now.timeIntervalSince(lastTypingSentAt) > 2 else { return }
        lastTypingSentAt = now
        stomp.send(destination: "/app/chat.typing.\(id)")
    }

    // MARK: - Sending

    /// Returns the conversation id, lazily creating one with the coach if needed.
    private func resolveConversationId(token: String) async throws -> String {
        if let conversationId { return conversationId }
        guard let coachProfileId else { throw APIError.unauthorized }
        let convo = try await api.startConversation(coachProfileId: coachProfileId, token: token)
        conversationId = convo.id
        return convo.id
    }

    func sendText() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let token = KeychainService.shared.getAccessToken() else { return }
        draft = ""
        do {
            let id = try await resolveConversationId(token: token)
            await send(SendMessageRequestDTO(content: text, attachments: nil), conversationId: id, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendAttachment(data: Data, filename: String, contentType: String, type: String) async {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            let id = try await resolveConversationId(token: token)
            let key = try await uploads.uploadFile(data: data, filename: filename, contentType: contentType, token: token)
            let attachment = SendAttachmentDTO(type: type, storageKey: key, fileName: filename)
            let body = SendMessageRequestDTO(content: "", attachments: [attachment])
            await send(body, conversationId: id, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Sends over the realtime socket when connected; falls back to REST otherwise.
    /// The server echoes sent messages back to our own queue, so we don't append optimistically.
    private func send(_ body: SendMessageRequestDTO, conversationId id: String, token: String) async {
        if let stomp, stomp.state == .connected, let json = encodeJSON(body) {
            stomp.send(destination: "/app/chat.send.\(id)", body: json)
            return
        }
        isSending = true
        defer { isSending = false }
        do {
            let msg = try await api.sendMessage(conversationId: id, body, token: token)
            if !messages.contains(where: { $0.id == msg.id }) { messages.append(msg) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func encodeJSON<T: Encodable>(_ value: T) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

private struct TypingEventDTO: Decodable {
    let conversationId: String
    let userId: String
}

private struct ReadReceiptEventDTO: Decodable {
    let conversationId: String
    let readByUserId: String
}
