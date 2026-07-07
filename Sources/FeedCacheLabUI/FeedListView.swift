import SwiftUI
import FeedCacheLabCore

/// The root demo view: a scrollable feed where each row's expensive
/// per-row state is constructed at most once (via `LazyBox`), and image
/// loads are served through an `LRUCache`-backed loader so re-scrolling
/// past an already-seen row never re-fetches its image.
public struct FeedListView: View {
    @Bindable var viewModel: FeedViewModel
    let tracker: RowConstructionTracker

    public init(viewModel: FeedViewModel, tracker: RowConstructionTracker = RowConstructionTracker()) {
        self.viewModel = viewModel
        self.tracker = tracker
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Feed Cache Lab")
                .safeAreaInset(edge: .bottom) {
                    MetricsOverlayView(
                        metrics: viewModel.cacheMetrics,
                        maxRowConstructions: tracker.maxConstructionCount
                    )
                }
                .task {
                    if viewModel.loadState == .idle {
                        await viewModel.load()
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading feed…")
        case .failed(let message):
            ContentUnavailableView(
                "Couldn't load feed",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .loaded:
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "No items",
                    systemImage: "tray"
                )
            } else {
                List(viewModel.items) { item in
                    FeedRowView(item: item, tracker: tracker)
                        .task { await viewModel.prefetchImage(for: item) }
                }
            }
        }
    }
}
