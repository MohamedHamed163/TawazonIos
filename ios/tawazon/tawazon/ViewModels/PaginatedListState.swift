//
//  PaginatedListState.swift
//  tawazon
//

import Foundation
import Observation

@Observable
final class PaginatedListState<Item: Decodable> {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var loadError: String?
    private(set) var hasMore = true
    private var nextPage = 0
    private let pageSize: Int

    init(pageSize: Int = 20) {
        self.pageSize = pageSize
    }

    func reset() {
        items = []
        nextPage = 0
        hasMore = true
        loadError = nil
    }

    func loadFirstPage(_ fetch: (Int, Int) async throws -> PageResponse<Item>) async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        nextPage = 0
        do {
            let response = try await fetch(0, pageSize)
            items = response.content
            hasMore = !response.last
            if !response.last {
                nextPage = response.page + 1
            }
        } catch {
            loadError = error.localizedDescription
            items = []
            hasMore = false
        }
        isLoading = false
    }

    func loadMore(_ fetch: (Int, Int) async throws -> PageResponse<Item>) async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        loadError = nil
        do {
            let response = try await fetch(nextPage, pageSize)
            items.append(contentsOf: response.content)
            hasMore = !response.last
            if !response.last {
                nextPage = response.page + 1
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoadingMore = false
    }
}
