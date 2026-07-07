import Foundation

/// Tracks how many times each row's backing `RowViewModel` has actually been
/// constructed, keyed by item id — the metric this whole demo exists to make
/// visible. In a correct lazy-init usage this count never exceeds `1` per
/// item, no matter how many times SwiftUI re-evaluates that row's view body.
///
/// Locked rather than actor-isolated because it is called synchronously
/// from inside a `LazyBox` factory closure during SwiftUI view
/// initialization, a context where `await`ing an actor isn't available.
public final class RowConstructionTracker: @unchecked Sendable {
    private var counts: [FeedItem.ID: Int] = [:]
    private let lock = NSLock()

    public init() {}

    public func recordConstruction(for id: FeedItem.ID) {
        lock.lock()
        defer { lock.unlock() }
        counts[id, default: 0] += 1
    }

    public func count(for id: FeedItem.ID) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return counts[id] ?? 0
    }

    public var maxConstructionCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return counts.values.max() ?? 0
    }
}
