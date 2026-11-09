//
//  ChatView.swift
//  tawazon
//

import AVKit
import PhotosUI
import SwiftUI

struct ChatView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model: ChatViewModel
    @State private var recorder = VoiceRecorder()
    @State private var photoItem: PhotosPickerItem?
    @State private var audioPlayer: AVPlayer?

    let coachName: String

    init(conversationId: String, coachName: String) {
        _model = State(initialValue: ChatViewModel(conversationId: conversationId))
        self.coachName = coachName
    }

    /// Opens (or starts) the chat with a coach by their profile id.
    init(coachProfileId: String, coachName: String) {
        _model = State(initialValue: ChatViewModel(coachProfileId: coachProfileId))
        self.coachName = coachName
    }

    private var textPrimary: Color { ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode) }
    private var textSecondary: Color { ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode) }
    private var accent: Color { themeManager.dynamicColorTheme.currentPrimary }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                messagesList
                if let err = model.errorMessage {
                    Text(err)
                        .textStyle(Typography.Style.caption, color: .red)
                        .padding(.horizontal)
                }
                composer
            }
        }
        .navigationTitle(coachName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .onDisappear { model.disconnect() }
        .onChange(of: model.draft) { _, _ in model.userIsTyping() }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await model.sendAttachment(
                        data: data,
                        filename: "photo-\(UUID().uuidString).jpg",
                        contentType: "image/jpeg",
                        type: "IMAGE"
                    )
                }
                photoItem = nil
            }
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(model.messages) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                    if model.isOtherTyping {
                        typingIndicator.id("typing-indicator")
                    }
                }
                .padding()
            }
            .onChange(of: model.messages.count) { _, _ in
                if let last = model.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: model.isOtherTyping) { _, typing in
                if typing { withAnimation { proxy.scrollTo("typing-indicator", anchor: .bottom) } }
            }
        }
    }

    private var typingIndicator: some View {
        HStack {
            Text(languageManager.localize("chat.typing"))
                .textStyle(Typography.Style.caption, color: textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
                .cornerRadius(16)
            Spacer(minLength: 40)
        }
    }

    private func isRead(_ msg: MessageDTO) -> Bool {
        msg.readAt != nil
    }

    private func isMine(_ msg: MessageDTO) -> Bool {
        msg.senderType.uppercased() == "SUBSCRIBER"
    }

    @ViewBuilder
    private func messageBubble(_ msg: MessageDTO) -> some View {
        HStack {
            if isMine(msg) { Spacer(minLength: 40) }
            VStack(alignment: isMine(msg) ? .trailing : .leading, spacing: 2) {
                VStack(alignment: .leading, spacing: 6) {
                    if let content = msg.content, !content.isEmpty {
                        Text(content)
                            .textStyle(Typography.Style.body, color: isMine(msg) ? .white : textPrimary)
                    }
                    if let attachments = msg.attachments {
                        ForEach(attachments) { att in
                            attachmentView(att, mine: isMine(msg))
                        }
                    }
                }
                .padding(12)
                .background(isMine(msg) ? accent : ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
                .cornerRadius(16)
                if isMine(msg) && isRead(msg) {
                    Label(languageManager.localize("chat.read"), systemImage: "checkmark.circle.fill")
                        .textStyle(Typography.Style.caption, color: textSecondary)
                        .padding(.trailing, 4)
                }
            }
            if !isMine(msg) { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private func attachmentView(_ att: MessageAttachmentDTO, mine: Bool) -> some View {
        switch att.type.uppercased() {
        case "IMAGE":
            AsyncImage(url: URL(string: att.url)) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                default: Rectangle().fill(textSecondary.opacity(0.15))
                }
            }
            .frame(width: 200, height: 200)
            .clipped()
            .cornerRadius(12)
        case "VOICE":
            Button {
                if let u = URL(string: att.url) {
                    audioPlayer = AVPlayer(url: u)
                    audioPlayer?.play()
                }
            } label: {
                Label(languageManager.localize("chat.playVoice"), systemImage: "play.circle.fill")
                    .textStyle(Typography.Style.subheadlineBold, color: mine ? .white : accent)
            }
        case "VIDEO":
            Button {
                if let u = URL(string: att.url) {
                    audioPlayer = AVPlayer(url: u)
                    audioPlayer?.play()
                }
            } label: {
                Label(languageManager.localize("chat.playVideo"), systemImage: "play.rectangle.fill")
                    .textStyle(Typography.Style.subheadlineBold, color: mine ? .white : accent)
            }
        default:
            Label(att.fileName ?? languageManager.localize("chat.attachment"), systemImage: "doc.fill")
                .textStyle(Typography.Style.caption, color: mine ? .white : textSecondary)
        }
    }

    private var composer: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3)
                    .foregroundColor(accent)
            }

            Button {
                Task { await toggleRecording() }
            } label: {
                Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.fill")
                    .font(.title3)
                    .foregroundColor(recorder.isRecording ? .red : accent)
            }

            TextField(languageManager.localize("chat.messagePlaceholder"), text: $model.draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                Task { await model.sendText() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(accent)
            }
            .disabled(model.isSending || model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
    }

    private func toggleRecording() async {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            if let data = try? Data(contentsOf: url) {
                await model.sendAttachment(
                    data: data,
                    filename: url.lastPathComponent,
                    contentType: "audio/m4a",
                    type: "VOICE"
                )
            }
            try? FileManager.default.removeItem(at: url)
        } else {
            _ = await recorder.start()
        }
    }
}
