//
//  ExerciseVideoView.swift
//  tawazon
//

import AVKit
import SwiftUI

struct ExerciseVideoView: View {
    @EnvironmentObject var languageManager: LanguageManager
    let videoURLString: String
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(languageManager.localize("today.video"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let url = URL(string: videoURLString) {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
