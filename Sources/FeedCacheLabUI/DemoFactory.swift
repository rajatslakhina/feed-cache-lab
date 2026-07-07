import Foundation
import FeedCacheLabCore

/// Builds the sample data and dependency graph the demo app runs against.
/// Kept in the library (not the app target) so the app target itself stays
/// a single `@main` file, per this repo's separation between "library" and
/// "thin app shell".
public enum DemoFactory {
    /// `@MainActor`-isolated because `FeedViewModel` itself is `@MainActor`
    /// (it's an `@Observable` view model meant to be read/written from
    /// SwiftUI view code only). This factory is called from `DemoAppApp`'s
    /// `body`, which SwiftUI's `App` protocol already isolates to the main
    /// actor, so the call site stays synchronous — this annotation just
    /// makes that isolation explicit instead of relying on inference.
    @MainActor
    public static func makeSampleFeedViewModel() -> FeedViewModel {
        let fetcher = SimulatedImageFetcher()
        let loader = CachingImageLoader(fetcher: fetcher)
        return FeedViewModel(imageLoader: loader) {
            (0..<24).map { index in
                FeedItem(
                    title: "Article \(index + 1)",
                    subtitle: "Cached lazily, loaded once",
                    // Safe: built from a hardcoded scheme + host and an
                    // interpolated non-negative Int, which never produces
                    // characters requiring percent-encoding — this string is
                    // provably a valid URL at compile time for every
                    // possible value of `index`.
                    imageURL: URL(string: "https://example.com/image/\(index).png")!
                )
            }
        }
    }
}
