import Foundation

/// Point-in-time observability snapshot for a cache: hits, misses, and
/// evictions. Exists so a UI layer (or a test) can assert on cache behavior
/// without reaching into the cache's private storage.
public struct CacheMetrics: Sendable, Equatable {
    public private(set) var hits: Int
    public private(set) var misses: Int
    public private(set) var evictions: Int

    public init(hits: Int = 0, misses: Int = 0, evictions: Int = 0) {
        self.hits = hits
        self.misses = misses
        self.evictions = evictions
    }

    public var totalLookups: Int { hits + misses }

    /// Fraction of lookups served from cache, in `[0, 1]`. Defined as `0`
    /// (rather than `NaN`) when there have been no lookups yet, so callers
    /// never have to special-case an empty-metrics state before displaying
    /// it.
    public var hitRate: Double {
        guard totalLookups > 0 else { return 0 }
        return Double(hits) / Double(totalLookups)
    }

    mutating func recordHit() { hits += 1 }
    mutating func recordMiss() { misses += 1 }
    mutating func recordEviction() { evictions += 1 }
}
