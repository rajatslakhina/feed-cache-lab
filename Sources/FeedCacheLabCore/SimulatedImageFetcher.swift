import Foundation

/// A deterministic, network-free stand-in for a real image-loading service.
///
/// Used in place of `URLSession` so the caching behavior above it can be
/// exercised in tests without network access, flaky timing, or real image
/// assets — while still modeling a realistic async boundary: simulated
/// latency, and a per-call counter used to *prove* that a cache sitting in
/// front of this fetcher is actually preventing redundant fetches (rather
/// than merely appearing to, which is the class of bug this whole demo is
/// built to make visible).
public actor SimulatedImageFetcher: ImageFetching {
    public private(set) var fetchCount = 0
    private let latencyNanoseconds: UInt64

    public init(simulatedLatencyMilliseconds: UInt64 = 5) {
        self.latencyNanoseconds = simulatedLatencyMilliseconds * 1_000_000
    }

    public func fetchImageData(for url: URL) async throws -> Data {
        fetchCount += 1
        if latencyNanoseconds > 0 {
            try await Task.sleep(nanoseconds: latencyNanoseconds)
        }
        // Deterministic "image" payload derived from the URL itself, so the
        // same input always produces the same output with no real network
        // stack or bundled assets involved.
        let payload = url.absoluteString.data(using: .utf8) ?? Data()
        return payload
    }
}
