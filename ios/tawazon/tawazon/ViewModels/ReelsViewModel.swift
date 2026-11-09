//
//  ReelsViewModel.swift
//  tawazon
//

import Foundation
import Observation

/// A single entry in the reels feed. `id` is a running counter so the same
/// video may appear more than once (after re-shuffling) without id collisions.
struct ReelItem: Identifiable {
    let id: Int
    let video: VideoMetadataResponse
}

/// Optimistic like state for a video, keyed by the video's id so every instance of the
/// same clip in the endlessly-shuffled feed shows the same heart + count.
struct ReelLikeState {
    var liked: Bool
    var count: Int
}

@MainActor
@Observable
final class ReelsViewModel {
    private let api = APIService.shared

    var items: [ReelItem] = []
    var isLoading = false
    var errorMessage: String?

    /// Per-video like overrides, keyed by `video.id`. Absent until the user interacts;
    /// reads fall back to the server-provided `likedByMe` / `likeCount`.
    var likeStates: [String: ReelLikeState] = [:]

    /// De-duplicated pool of playable videos used to build the endless feed.
    private var pool: [VideoMetadataResponse] = []
    private var counter = 0

    func load() async {
        guard items.isEmpty else { return } // load once; keeps shuffle & scroll position
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = KeychainService.shared.getAccessToken()
            let page = try await api.getVideos(page: 0, size: 50, token: token)
            pool = page.content.filter { !$0.streamUrl.isEmpty }
            items = makeBatch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Appends another shuffled batch when the user nears the end so the feed
    /// loops forever (all coaches' videos, in a fresh random order each pass).
    func appendBatchIfNeeded(currentId: Int?) {
        guard let currentId, !pool.isEmpty else { return }
        guard let idx = items.firstIndex(where: { $0.id == currentId }) else { return }
        if idx >= items.count - 2 {
            items.append(contentsOf: makeBatch())
        }
    }

    // MARK: - Likes

    func likeState(for video: VideoMetadataResponse) -> ReelLikeState {
        likeStates[video.id] ?? ReelLikeState(liked: video.likedByMe, count: video.likeCount)
    }

    /// Toggles the like (heart button). Optimistic; reconciled with the server response.
    func toggleLike(for video: VideoMetadataResponse) {
        let previous = likeState(for: video)
        let nowLiked = !previous.liked
        likeStates[video.id] = ReelLikeState(
            liked: nowLiked,
            count: max(0, previous.count + (nowLiked ? 1 : -1))
        )
        Task { await commitLike(videoId: video.id, like: nowLiked, previous: previous) }
    }

    /// Double-tap gesture: always likes, never unlikes — matching Instagram/TikTok.
    func likeByDoubleTap(for video: VideoMetadataResponse) {
        let previous = likeState(for: video)
        guard !previous.liked else { return }
        likeStates[video.id] = ReelLikeState(liked: true, count: previous.count + 1)
        Task { await commitLike(videoId: video.id, like: true, previous: previous) }
    }

    private func commitLike(videoId: String, like: Bool, previous: ReelLikeState) async {
        do {
            let token = KeychainService.shared.getAccessToken()
            let response = try await (like
                ? api.likeVideo(id: videoId, token: token)
                : api.unlikeVideo(id: videoId, token: token))
            // Reconcile optimistic state with the server's authoritative count.
            likeStates[videoId] = ReelLikeState(liked: response.liked, count: response.likeCount)
        } catch {
            likeStates[videoId] = previous // revert on failure
        }
    }

    private func makeBatch() -> [ReelItem] {
        pool.shuffled().map { video in
            defer { counter += 1 }
            return ReelItem(id: counter, video: video)
        }
    }
}
