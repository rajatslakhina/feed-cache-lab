import Foundation

/// A minimal, dependency-free least-recently-used cache.
///
/// This models the caching behavior SwiftUI's `AsyncImage` gained at
/// WWDC26 (automatic HTTP response caching so scrolling a list doesn't
/// re-fetch images it has already shown) without depending on `URLCache`,
/// `URLSession`, or any networking stack — so the eviction and hit/miss
/// logic can be unit tested headlessly, on any platform, with no network
/// access required.
///
/// Deliberately not thread-safe on its own: callers that need concurrent
/// access wrap it in an `actor` (see `CachingImageLoader`) rather than
/// building locking into the eviction policy itself, keeping this type
/// simple to read, test, and reason about in isolation.
public final class LRUCache<Key: Hashable, Value> {
    private final class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }

    private var nodes: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?

    public let capacity: Int
    public private(set) var metrics = CacheMetrics()

    /// - Parameter capacity: Maximum number of entries retained. `0` is a
    ///   valid, explicitly-handled edge case: it means "retain nothing" —
    ///   every read is a guaranteed miss and every write is a no-op, rather
    ///   than an unchecked assumption that some positive capacity exists.
    ///   Negative values are clamped to `0` for the same reason.
    public init(capacity: Int) {
        self.capacity = max(0, capacity)
    }

    public var count: Int { nodes.count }
    public var isEmpty: Bool { nodes.isEmpty }

    @discardableResult
    public func value(forKey key: Key) -> Value? {
        guard let node = nodes[key] else {
            metrics.recordMiss()
            return nil
        }
        metrics.recordHit()
        moveToFront(node)
        return node.value
    }

    public func setValue(_ value: Value, forKey key: Key) {
        guard capacity > 0 else { return }

        if let existing = nodes[key] {
            existing.value = value
            moveToFront(existing)
            return
        }

        let node = Node(key: key, value: value)
        nodes[key] = node
        insertAtFront(node)

        if nodes.count > capacity {
            evictLeastRecentlyUsed()
        }
    }

    public func removeAll() {
        nodes.removeAll()
        head = nil
        tail = nil
    }

    // MARK: - Doubly linked list bookkeeping

    private func insertAtFront(_ node: Node) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil { tail = node }
    }

    private func moveToFront(_ node: Node) {
        guard head !== node else { return }
        detach(node)
        insertAtFront(node)
    }

    private func detach(_ node: Node) {
        let prev = node.prev
        let next = node.next
        prev?.next = next
        next?.prev = prev
        if head === node { head = next }
        if tail === node { tail = prev }
        node.prev = nil
        node.next = nil
    }

    private func evictLeastRecentlyUsed() {
        guard let lru = tail else { return }
        detach(lru)
        nodes.removeValue(forKey: lru.key)
        metrics.recordEviction()
    }
}
