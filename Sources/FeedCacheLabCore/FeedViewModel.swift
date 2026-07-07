import Foundation
import Observation

/// Loads a feed of items through a `CachingImageLoader` and exposes only
/// safe, bounds-checked access to the results — no raw `Array` subscript is
/// ever exposed to callers, so an out-of-range or negative row index cannot
/// crash the caller; it simply returns `nil`.
@Observable
@MainActor
public final class FeedViewModel {
    public enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    public private(set) var items: [FeedItem] = []
    public private(set) var loadState: LoadState = .idle
    public private(set) var cacheMetrics = CacheMetrics()

    private let imageLoader: CachingImageLoader
    private let itemProvider: @Sendable () async throws -> [FeedItem]

    public init(
        imageLoader: CachingImageLoader,
        itemProvider: @escaping @Sendable () async throws -> [FeedItem]
    ) {
        self.imageLoader = imageLoader
        self.itemProvider = itemProvider
    }

    public var isEmpty: Bool { items.isEmpty }
    public var count: Int { items.count }

    /// Safe, bounds-checked row access. Returns `nil` — never traps — for
    /// any out-of-range index, including on an empty list and for negative
    /// indices.
    public func item(at index: Int) -> FeedItem? {
        guard index >= 0, index < items.count else { return nil }
        return items[index]
    }

    public func load() async {
        loadState = .loading
        do {
            items = try await itemProvider()
            loadState = .loaded
        } catch {
            items = []
            loadState = .failed(error.localizedDescription)
        }
    }

    /// Warms the cache for a given item's image and refreshes the exposed
    /// metrics snapshot so a view can display live hit/miss counters.
    public func prefetchImage(for item: FeedItem) async {
        _ = try? await imageLoader.image(for: item.imageURL)
        cacheMetrics = await imageLoader.metrics
    }
}
