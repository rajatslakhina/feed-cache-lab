import Foundation
import Testing
@testable import FeedCacheLabCore

struct CachingImageLoaderTests {
    @Test func secondFetchOfSameURLIsServedFromCache() async throws {
        let fetcher = SimulatedImageFetcher(simulatedLatencyMilliseconds: 0)
        let loader = CachingImageLoader(fetcher: fetcher)
        let url = URL(string: "https://example.com/a.png")!

        _ = try await loader.image(for: url)
        _ = try await loader.image(for: url)

        let fetchCount = await fetcher.fetchCount
        #expect(fetchCount == 1, "second request for the same URL should hit the cache, not the fetcher")

        let metrics = await loader.metrics
        #expect(metrics.hits == 1)
        #expect(metrics.misses == 1)
    }

    @Test func differentURLsAreFetchedIndependently() async throws {
        let fetcher = SimulatedImageFetcher(simulatedLatencyMilliseconds: 0)
        let loader = CachingImageLoader(fetcher: fetcher)

        _ = try await loader.image(for: URL(string: "https://example.com/a.png")!)
        _ = try await loader.image(for: URL(string: "https://example.com/b.png")!)

        let fetchCount = await fetcher.fetchCount
        #expect(fetchCount == 2)

        let metrics = await loader.metrics
        #expect(metrics.misses == 2)
        #expect(metrics.hits == 0)
    }

    @Test func evictionUnderLowCapacityForcesRefetch() async throws {
        let fetcher = SimulatedImageFetcher(simulatedLatencyMilliseconds: 0)
        let loader = CachingImageLoader(fetcher: fetcher, cacheCapacity: 1)
        let urlA = URL(string: "https://example.com/a.png")!
        let urlB = URL(string: "https://example.com/b.png")!

        _ = try await loader.image(for: urlA) // miss, cache: [a]
        _ = try await loader.image(for: urlB) // miss, evicts a, cache: [b]
        _ = try await loader.image(for: urlA) // miss again, a was evicted

        let fetchCount = await fetcher.fetchCount
        #expect(fetchCount == 3)
    }
}
