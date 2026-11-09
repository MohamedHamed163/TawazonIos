//
//  ReelsView.swift
//  tawazon
//
//  TikTok-style vertical feed of coach video content. All coaches' videos are
//  fetched, shuffled and paged full-screen. Each clip autoplays and seamlessly
//  loops; the feed re-shuffles endlessly so swiping never dead-ends.
//
//  Playback is backed by a small pool of looping AVPlayers (`ReelPlayerPool`)
//  that preloads the next clips so swipes start instantly, and audio is forced
//  through the `.playback` session category so sound plays even when the phone's
//  physical Ring/Silent switch is set to silent.
//

import AVFoundation
import AVKit
import SwiftUI

// MARK: - Audio session

/// Reels play with sound regardless of the hardware mute switch — the same behaviour
/// as TikTok/Instagram/YouTube. Without a `.playback` category, AVPlayer follows the
/// silent switch and appears "muted on some phones".
enum ReelsAudioSession {
    static func activate() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }

    /// Let other apps' audio (e.g. music) resume when the user leaves the feed.
    static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Looping player + pool

/// An `AVQueuePlayer` wired to an `AVPlayerLooper` for gapless looping (no seek-to-zero
/// hitch). The looper must be retained for looping to continue, so it lives here.
@MainActor
final class LoopingPlayer {
    let player: AVQueuePlayer
    private var looper: AVPlayerLooper?

    init?(urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        item.preferredForwardBufferDuration = 3 // start fast; short buffer for short-form
        let queue = AVQueuePlayer()
        queue.automaticallyWaitsToMinimizeStalling = false
        queue.actionAtItemEnd = .advance
        self.player = queue
        self.looper = AVPlayerLooper(player: queue, templateItem: item)
    }
}

/// A small LRU pool of looping players keyed by `ReelItem.id`. Reusing and preloading
/// players (instead of building/tearing one down per page) is what makes swiping smooth.
@MainActor
@Observable
final class ReelPlayerPool {
    private var cache: [Int: LoopingPlayer] = [:]
    private var lru: [Int] = []
    private let capacity = 5 // current + ~2 ahead + ~2 behind

    /// Single source of truth for mute; `toggleMute()` applies it to every pooled player so
    /// unmuting also unmutes the clips already preloaded ahead.
    private(set) var isMuted = false

    func toggleMute() {
        isMuted.toggle()
        for entry in cache.values { entry.player.isMuted = isMuted }
    }

    /// Returns a ready looping player for the item, creating and caching one on first use.
    /// Hands back the `LoopingPlayer` (not the bare `AVQueuePlayer`) so the calling view can
    /// retain the `AVPlayerLooper`; looping then keeps working even after this entry is evicted
    /// from the cache — otherwise the freed looper leaves the clip black when it tries to loop.
    func loopingPlayer(for item: ReelItem) -> LoopingPlayer? {
        if let existing = cache[item.id] {
            touch(item.id)
            return existing
        }
        guard let looping = LoopingPlayer(urlString: item.video.streamUrl) else { return nil }
        looping.player.isMuted = isMuted
        cache[item.id] = looping
        lru.append(item.id)
        evictIfNeeded()
        return looping
    }

    /// Warms players for upcoming items so their first frame is ready before the swipe.
    func preload(_ items: [ReelItem]) {
        for item in items where cache[item.id] == nil {
            _ = loopingPlayer(for: item) // creation begins buffering...
            cache[item.id]?.player.pause() // ...but stays paused until it becomes active
        }
    }

    func pauseAll() {
        for entry in cache.values { entry.player.pause() }
    }

    private func touch(_ id: Int) {
        if let idx = lru.firstIndex(of: id) { lru.remove(at: idx) }
        lru.append(id)
    }

    private func evictIfNeeded() {
        while cache.count > capacity, let oldest = lru.first {
            lru.removeFirst()
            cache[oldest]?.player.pause()
            cache[oldest] = nil
        }
    }
}

// MARK: - Cached thumbnail

/// In-memory thumbnail cache so scrolling back to a clip doesn't re-download its poster.
@MainActor
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSURL, UIImage>()
    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func store(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
}

private struct CachedThumbnail: View {
    let urlString: String?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                Color.black
            }
        }
        .task(id: urlString) { await load() }
    }

    private func load() async {
        guard let urlString, let url = URL(string: urlString) else { return }
        if let cached = ThumbnailCache.shared.image(for: url) {
            image = cached
            return
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let ui = UIImage(data: data) else { return }
        ThumbnailCache.shared.store(ui, for: url)
        image = ui
    }
}

// MARK: - Feed

struct ReelsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var model = ReelsViewModel()
    @State private var pool = ReelPlayerPool()
    @State private var currentId: Int?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if model.isLoading && model.items.isEmpty {
                ProgressView().tint(.white)
            } else if let err = model.errorMessage, model.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.7))
                    Text(err)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if model.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "play.slash")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.7))
                    Text(languageManager.localize("content.emptyTitle"))
                        .foregroundColor(.white.opacity(0.85))
                }
            } else {
                feed
            }
        }
        .task {
            ReelsAudioSession.activate()
            await model.load()
        }
        .onDisappear {
            pool.pauseAll()
            ReelsAudioSession.deactivate()
        }
    }

    private var feed: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(model.items) { item in
                        ReelPageView(
                            item: item,
                            isActive: currentId == item.id,
                            pool: pool,
                            model: model
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentId)
            .scrollIndicators(.hidden)
            .onAppear { if currentId == nil { currentId = model.items.first?.id } }
            .onChange(of: currentId) { _, newId in
                model.appendBatchIfNeeded(currentId: newId)
                preload(around: newId)
            }
            .onChange(of: model.items.count) { _, _ in
                preload(around: currentId)
            }
        }
    }

    /// Warm the next couple of clips so they're ready before the user swipes to them.
    private func preload(around id: Int?) {
        guard let id, let idx = model.items.firstIndex(where: { $0.id == id }) else { return }
        let upper = min(idx + 3, model.items.count)
        guard idx + 1 < upper else { return }
        pool.preload(Array(model.items[(idx + 1)..<upper]))
    }
}

// MARK: - Single reel page

private struct ReelPageView: View {
    let item: ReelItem
    let isActive: Bool
    let pool: ReelPlayerPool
    let model: ReelsViewModel

    // Retain the `LoopingPlayer` (not the bare player) for as long as this page is on screen,
    // so its `AVPlayerLooper` survives pool eviction. Otherwise the looper is freed and the clip
    // goes black the moment it tries to loop.
    @State private var looping: LoopingPlayer?
    @State private var isPlaying = true
    @State private var showHeartBurst = false

    private var video: VideoMetadataResponse { item.video }
    private var like: ReelLikeState { model.likeState(for: video) }
    private var player: AVQueuePlayer? { looping?.player }

    var body: some View {
        ZStack {
            Color.black

            CachedThumbnail(urlString: video.thumbnailUrl)

            if let player {
                PlayerLayerView(player: player)
            }

            // Double-tap to like, single-tap to play/pause.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { doubleTapLike() }
                .onTapGesture { togglePlayback() }

            if !isPlaying {
                Image(systemName: "play.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(radius: 8)
                    .allowsHitTesting(false)
            }

            if showHeartBurst {
                Image(systemName: "heart.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.white)
                    .shadow(radius: 12)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                    .allowsHitTesting(false)
            }

            overlay
        }
        .clipped()
        .onAppear {
            let l = looping ?? pool.loopingPlayer(for: item)
            looping = l
            if isActive { l?.player.play(); isPlaying = true } else { l?.player.pause() }
        }
        .onDisappear { player?.pause() }
        .onChange(of: isActive) { _, active in
            let l = looping ?? pool.loopingPlayer(for: item)
            looping = l
            if active {
                l?.player.play()
                isPlaying = true
            } else {
                l?.player.pause()
                isPlaying = false
            }
        }
    }

    private var overlay: some View {
        VStack {
            HStack {
                Spacer()
                Button { pool.toggleMute() } label: {
                    Image(systemName: pool.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.black.opacity(0.35), in: Circle())
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)

            Spacer()

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    if let coach = video.coachName, !coach.isEmpty {
                        Label(coach, systemImage: "person.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    if let desc = video.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                }

                Spacer()

                likeButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }

    private var likeButton: some View {
        VStack(spacing: 4) {
            Button { model.toggleLike(for: video) } label: {
                Image(systemName: like.liked ? "heart.fill" : "heart")
                    .font(.system(size: 30))
                    .foregroundStyle(like.liked ? .red : .white)
                    .scaleEffect(like.liked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: like.liked)
                    .shadow(radius: 4)
            }
            Text(compactCount(like.count))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .shadow(radius: 3)
        }
    }

    // MARK: Actions

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func doubleTapLike() {
        model.likeByDoubleTap(for: video)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showHeartBurst = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.easeOut(duration: 0.25)) { showHeartBurst = false }
        }
    }

    private func compactCount(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000).replacingOccurrences(of: ".0M", with: "M")
        }
        if n >= 1_000 {
            return String(format: "%.1fK", Double(n) / 1_000).replacingOccurrences(of: ".0K", with: "K")
        }
        return "\(n)"
    }
}

// MARK: - Full-bleed AVPlayer layer (crops to fill, no default controls)

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerUIView {
        let view = PlayerContainerUIView()
        view.backgroundColor = .black
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerContainerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerContainerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
