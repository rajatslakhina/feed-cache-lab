# FeedCacheLab

**A scroll list where "it feels fast" is a measured claim, not a vibe.** FeedCacheLab is a small SwiftUI app that puts two numbers on screen at all times — cache hit rate and max per-row construction count — and proves, live, that a real image cache and real lazy state initialization are doing their job as you scroll, instead of asking you to just trust that they are.

**Runnable demo:** [feed-cache-lab-demo-app](https://github.com/rajatslakhina/feed-cache-lab-demo-app) — a separate app that adds this package as a remote Swift Package dependency and runs it. This repo contains only the library.

## The problem

At WWDC26, `AsyncImage` gained automatic HTTP-response caching so scrolling a list doesn't re-fetch images it already showed you, and `@State`-held `Observable` objects started deferring their construction instead of re-running their initializer on every view re-evaluation. Both are genuine performance wins. Both are also easy to *think* you've correctly adopted while actually undermining them with one wrong line — a cache keyed on the wrong thing, a "lazy" wrapper that's secretly eager, a view identity that resets on every scroll frame and silently defeats the whole optimization.

The failure mode here is specifically insidious: the app still works. It just quietly re-fetches images and re-constructs view models it didn't need to, and nothing about the UI tells you that's happening — until a profiler session on a slow device turns up a network waterfall that shouldn't exist. This repo is built around making that invisible failure mode visible and testable, rather than building "a demo of AsyncImage."

## What's actually in here

- **`LRUCache<Key, Value>`** — a dependency-free least-recently-used cache modeling the caching behavior `AsyncImage` gained, with hit/miss/eviction metrics as first-class, inspectable state.
- **`LazyBox<Value>`** — a deferred-construction wrapper modeling the `@State` lazy-init behavior, with a construction counter that makes "was this actually only built once?" an assertion instead of an assumption.
- **`CachingImageLoader`** — an actor that puts an `LRUCache` in front of a fetcher, so the caching behavior is exercised through a realistic async boundary.
- **`FeedViewModel` / `RowViewModel`** — `@Observable` view models with bounds-checked, crash-free access to feed data.
- **`FeedListView`** (SwiftUI) — renders the feed with a live metrics bar (cache hits, misses, hit rate, max row-construction count) pinned to the bottom, so the effect of the caching/lazy-init strategy is visible in the running app, not just in a test file.

## Design decisions and trade-offs

**Two library targets, not one.** `FeedCacheLabCore` (pure Swift/Foundation — the cache, the lazy box, the view models, the simulated fetcher) is separated from `FeedCacheLabUI` (SwiftUI views). This wasn't the simplest option — a single target would have been less code to write — but it means the core caching and lazy-init logic can be built and unit-tested on any platform, including headless Linux CI, with zero UIKit/SwiftUI dependency. The alternative (one target, SwiftUI views alongside the logic they use) would make the whole module untestable outside of Xcode/macOS. Given that the entire point of this repo is *proving* the caching and lazy-init behavior rather than asserting it, testability without a Simulator was worth the extra target.

**A hand-rolled `LRUCache` instead of `URLCache`/`NSCache`.** `NSCache` doesn't expose hit/miss/eviction counts, and `URLCache` needs a real or mocked `URLSession` to exercise. Rolling a small doubly-linked-list LRU cache directly is more code, but it's the only way to make "did this actually cache, and did it evict the right entry" a same-file unit test rather than an integration test requiring network mocking.

**A simulated fetcher instead of a real network call.** `SimulatedImageFetcher` derives a deterministic payload from the URL itself and counts its own invocations. This means the tests that prove caching prevents redundant fetches (`CachingImageLoaderTests`) are deterministic and instant, with no flaky network dependency — at the cost of not exercising real `URLSession`/HTTP caching semantics, which is an explicit, disclosed simplification rather than an oversight.

**`LazyBox` as an enum state machine, not an optional + a flag.** An earlier draft tracked "has this been constructed yet" with a `Value?` plus a separate boolean, which meant a code path could theoretically observe "not constructed" but "no factory available" at the same time — exactly the kind of inconsistent-state bug that tends to get papered over with a force-unwrap. Modeling it as `enum State { case pending(() -> Value), resolved(Value) }` makes that inconsistent state unrepresentable and lets the compiler enforce exhaustiveness, instead of relying on a runtime invariant.

**The runnable demo lives in its own separate repo, consumed as a remote dependency.** Two earlier iterations of this pattern were tried and rejected. First, letting Xcode run the package's own `.executableTarget` directly on Simulator — this crashes on every launch (`__BKSHIDEvent__BUNDLE_IDENTIFIER_FOR_CURRENT_PROCESS_IS_NIL__`) because that convenience synthesizes a bundle identifier as a local, non-git-tracked Xcode setting. Second, nesting a hand-authored `DemoApp.xcodeproj` inside this same repo, wired to the library via a *local* Swift Package reference (`relativePath = "../"`) — better, but it only proves the library builds when sitting right next to its consumer on disk, not that it works as a published dependency. The current approach — [feed-cache-lab-demo-app](https://github.com/rajatslakhina/feed-cache-lab-demo-app), a fully separate repo depending on this one via a **remote** Swift Package reference tracking `main` — is slower to set up, but it's the only version that proves this package is genuinely consumable the way any real third-party dependency would be.

## How to run the demo

Open [feed-cache-lab-demo-app](https://github.com/rajatslakhina/feed-cache-lab-demo-app) — this repo is library-only and intentionally has no app target to run.

## What verification this actually got

Being specific here on purpose, because "builds" and "runs" get conflated too easily:

- **`swift build --target FeedCacheLabCore`** succeeds, and **`swift test`** passes all 23 tests in `FeedCacheLabCoreTests` — covering `LRUCache` edge cases (empty cache, zero/negative capacity, eviction ordering, overwrite-vs-evict), `LazyBox` construction-count guarantees, `CachingImageLoader` hit/miss behavior against a simulated fetcher, and `FeedViewModel`'s bounds-checked row access (negative index, out-of-range index, empty list). This is the strongest tier of verification actually achieved, and it covers 100% of the pure-Swift core logic.
- **`FeedCacheLabUI` (the SwiftUI layer)** got rigorous manual review rather than a compiler pass in headless environments: every collection access in the UI layer goes through `ForEach`/`List` over `Identifiable` items (no manual index subscripting), and the one force-unwrap in the package (`DemoFactory`'s `URL(string:)!`) is on a hardcoded-format literal with a comment explaining why it can't fail.
- Actual on-Simulator verification, if it happened, lives with the demo app's own repo and README — check there for the current, honest status of that claim.

## Visuals

Screenshots live in the [feed-cache-lab-demo-app](https://github.com/rajatslakhina/feed-cache-lab-demo-app) repo, since that's where the app is actually run from.
