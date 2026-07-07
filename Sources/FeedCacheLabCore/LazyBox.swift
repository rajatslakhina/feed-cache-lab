import Foundation

/// Defers construction of an expensive value until it is first read, then
/// caches it for the lifetime of the box.
///
/// Models the behavior SwiftUI's `@State` gained for `Observable` objects in
/// Swift 6.4 / WWDC26: the *view struct* holding a `@State` property can be
/// re-initialized many times (e.g. on every scroll-driven body
/// re-evaluation), but the state it owns should only ever be constructed
/// once. `LazyBox` makes that distinction explicit and testable outside of a
/// SwiftUI runtime: `LazyBox.init` itself can run cheaply, arbitrarily many
/// times, while the `factory` closure it wraps is guaranteed to run at most
/// once per box — modeled with an enum rather than an optional-plus-flag pair,
/// so "resolved vs. pending" is exhaustively checked by the compiler and
/// there is no state for a force-unwrap to fail on.
///
/// Not `Sendable` and not internally synchronized: this mirrors `@State`
/// itself, which is only safe to read/write from the main actor. Every use
/// in this package is confined to `@MainActor`-isolated SwiftUI view code.
public final class LazyBox<Value> {
    private enum State {
        case pending(() -> Value)
        case resolved(Value)
    }

    private var state: State

    /// Number of times `factory` has actually been invoked. In a correct
    /// lazy-init usage this never exceeds `1`, no matter how many times the
    /// box is constructed or `.value` is read.
    public private(set) var constructionCount = 0

    public init(_ factory: @escaping () -> Value) {
        self.state = .pending(factory)
    }

    public var value: Value {
        switch state {
        case .resolved(let value):
            return value
        case .pending(let factory):
            let constructed = factory()
            constructionCount += 1
            state = .resolved(constructed)
            return constructed
        }
    }

    public var hasBeenConstructed: Bool {
        if case .resolved = state { return true }
        return false
    }
}
