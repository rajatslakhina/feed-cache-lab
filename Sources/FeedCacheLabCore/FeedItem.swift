import Foundation

/// A single row of demo feed content. Deliberately trivial — the point of
/// this package is the caching/lazy-init behavior around items, not the
/// items themselves.
public struct FeedItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let imageURL: URL

    public init(id: UUID = UUID(), title: String, subtitle: String, imageURL: URL) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
    }
}
