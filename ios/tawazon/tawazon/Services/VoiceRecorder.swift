//
//  VoiceRecorder.swift
//  tawazon
//

import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class VoiceRecorder: NSObject {
    private var recorder: AVAudioRecorder?
    private(set) var isRecording = false
    private(set) var lastRecordingURL: URL?

    /// Requests mic permission and starts recording to a temp .m4a file. Returns false if denied/failed.
    func start() async -> Bool {
        let granted = await requestPermission()
        guard granted else { return false }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let rec = try AVAudioRecorder(url: url, settings: settings)
            rec.record()
            recorder = rec
            lastRecordingURL = url
            isRecording = true
            return true
        } catch {
            isRecording = false
            return false
        }
    }

    /// Stops recording and returns the recorded file URL, if any.
    @discardableResult
    func stop() -> URL? {
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return lastRecordingURL
    }

    func cancel() {
        recorder?.stop()
        if let url = lastRecordingURL { try? FileManager.default.removeItem(at: url) }
        recorder = nil
        lastRecordingURL = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }
}
