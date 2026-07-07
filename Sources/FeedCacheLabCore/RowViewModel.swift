import Foundation
import Observation

/// Deliberately lightweight per-row state, intended to be constructed at
/// most once per row identity via `LazyBox`, regardless of how many times
/// the owning row view's own initializer runs (e.g. on every scroll-driven
/// body re-evaluation).
@Observable
@MainActor
public final class RowViewModel {
    public let item: FeedItem
    public private(set) var isImageLoaded = false

    public init(item: FeedItem) {
        self.item = item
    }

    public func markImageLoaded() {
        isImageLoaded = true
    }
}
