import SwiftUI
import FeedCacheLabCore

struct FeedRowView: View {
    let item: FeedItem
    let tracker: RowConstructionTracker

    @State private var rowViewModelBox: LazyBox<RowViewModel>

    init(item: FeedItem, tracker: RowConstructionTracker) {
        self.item = item
        self.tracker = tracker
        // `LazyBox.init` itself is cheap and can run every time this view's
        // own `init` runs (e.g. once per scroll-driven body re-evaluation)
        // with no cost, because `@State` guarantees SwiftUI keeps only the
        // *first* instance for this view's identity. The `RowViewModel`
        // inside the closure is therefore constructed at most once — the
        // exact behavior this demo exists to make visible via `tracker`.
        _rowViewModelBox = State(initialValue: LazyBox {
            tracker.recordConstruction(for: item.id)
            return RowViewModel(item: item)
        })
    }

    var body: some View {
        let viewModel = rowViewModelBox.value
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay {
                    if viewModel.isImageLoaded {
                        Image(systemName: "photo.fill")
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .task {
            viewModel.markImageLoaded()
        }
    }
}
