import Foundation

/// Coordinates fetching with an `LRUCache`, so repeated requests for the
/// same URL are served from cache instead of re-invoking the underlying
/// fetcher — mirroring the "`AsyncImage` avoids reloads on scroll" behavior
/// introduced at WWDC26, but as a plain, testable Swift type with no
/// SwiftUI/UIKit dependency.
public actor CachingImageLoader {
    private let fetcher: any ImageFetching
    private let cache: LRUCache<URL, Data>

    public init(fetcher: any ImageFetching, cacheCapacity: Int = 50) {
        self.fetcher = fetcher
        self.cache = LRUCache(capacity: cacheCapacity)
    }

    public var metrics: CacheMetrics { cache.metrics }

    public func image(for url: URL) async throws -> Data {
        if let cached = cache.value(forKey: url) {
            return cached
        }
        let data = try await fetcher.fetchImageData(for: url)
        cache.setValue(data, forKey: url)
        return data
    }
}
