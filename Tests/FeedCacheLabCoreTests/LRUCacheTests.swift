import Testing
@testable import FeedCacheLabCore

struct LRUCacheTests {
    @Test func missOnEmptyCache() {
        let cache = LRUCache<String, Int>(capacity: 3)
        #expect(cache.value(forKey: "missing") == nil)
        #expect(cache.metrics.misses == 1)
        #expect(cache.metrics.hits == 0)
    }

    @Test func hitAfterSet() {
        let cache = LRUCache<String, Int>(capacity: 3)
        cache.setValue(42, forKey: "a")
        #expect(cache.value(forKey: "a") == 42)
        #expect(cache.metrics.hits == 1)
        #expect(cache.metrics.misses == 0)
    }

    @Test func zeroCapacityNeverRetainsAnything() {
        let cache = LRUCache<String, Int>(capacity: 0)
        cache.setValue(1, forKey: "a")
        #expect(cache.isEmpty)
        #expect(cache.value(forKey: "a") == nil)
        #expect(cache.metrics.misses == 1)
    }

    @Test func negativeCapacityIsClampedToZero() {
        let cache = LRUCache<String, Int>(capacity: -5)
        #expect(cache.capacity == 0)
        cache.setValue(1, forKey: "a")
        #expect(cache.isEmpty)
    }

    @Test func evictsLeastRecentlyUsedWhenOverCapacity() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, forKey: "a")
        cache.setValue(2, forKey: "b")
        cache.setValue(3, forKey: "c") // evicts "a"

        #expect(cache.value(forKey: "a") == nil)
        #expect(cache.value(forKey: "b") == 2)
        #expect(cache.value(forKey: "c") == 3)
        #expect(cache.metrics.evictions == 1)
        #expect(cache.count == 2)
    }

    @Test func accessingAKeyProtectsItFromEviction() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, forKey: "a")
        cache.setValue(2, forKey: "b")
        _ = cache.value(forKey: "a") // "a" is now most-recently-used
        cache.setValue(3, forKey: "c") // should evict "b", not "a"

        #expect(cache.value(forKey: "a") == 1)
        #expect(cache.value(forKey: "b") == nil)
        #expect(cache.value(forKey: "c") == 3)
    }

    @Test func overwritingAnExistingKeyDoesNotEvictOthers() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, forKey: "a")
        cache.setValue(2, forKey: "b")
        cache.setValue(99, forKey: "a") // overwrite, not a new entry

        #expect(cache.count == 2)
        #expect(cache.value(forKey: "a") == 99)
        #expect(cache.value(forKey: "b") == 2)
        #expect(cache.metrics.evictions == 0)
    }

    @Test func removeAllClearsEntriesAndOrdering() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.setValue(1, forKey: "a")
        cache.setValue(2, forKey: "b")
        cache.removeAll()

        #expect(cache.isEmpty)
        #expect(cache.value(forKey: "a") == nil)

        // Cache must still function correctly after being cleared.
        cache.setValue(3, forKey: "c")
        #expect(cache.value(forKey: "c") == 3)
    }
}
