import Foundation
import Testing
@testable import FeedCacheLabCore

@MainActor
struct FeedViewModelTests {
    private func makeViewModel(
        items: [FeedItem] = [],
        shouldThrow: Bool = false
    ) -> FeedViewModel {
        let loader = CachingImageLoader(fetcher: SimulatedImageFetcher(simulatedLatencyMilliseconds: 0))
        return FeedViewModel(imageLoader: loader) {
            if shouldThrow {
                struct LoadError: Error {}
                throw LoadError()
            }
            return items
        }
    }

    @Test func itemAtIndexIsNilOnEmptyList() async {
        let viewModel = makeViewModel(items: [])
        await viewModel.load()
        #expect(viewModel.item(at: 0) == nil)
        #expect(viewModel.item(at: -1) == nil)
        #expect(viewModel.isEmpty == true)
    }

    @Test func itemAtNegativeIndexNeverTraps() async {
        let sample = FeedItem(title: "A", subtitle: "B", imageURL: URL(string: "https://example.com/1.png")!)
        let viewModel = makeViewModel(items: [sample])
        await viewModel.load()
        #expect(viewModel.item(at: -1) == nil)
    }

    @Test func itemAtOutOfRangeIndexReturnsNil() async {
        let sample = FeedItem(title: "A", subtitle: "B", imageURL: URL(string: "https://example.com/1.png")!)
        let viewModel = makeViewModel(items: [sample])
        await viewModel.load()
        #expect(viewModel.item(at: 1) == nil)
        #expect(viewModel.item(at: 1000) == nil)
        #expect(viewModel.item(at: 0) == sample)
    }

    @Test func loadPopulatesItemsAndState() async {
        let sample = FeedItem(title: "A", subtitle: "B", imageURL: URL(string: "https://example.com/1.png")!)
        let viewModel = makeViewModel(items: [sample])

        #expect(viewModel.loadState == .idle)
        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.count == 1)
        #expect(viewModel.item(at: 0) == sample)
    }

    @Test func loadFailurePathSetsFailedStateAndEmptyItems() async {
        let viewModel = makeViewModel(shouldThrow: true)
        await viewModel.load()

        guard case .failed = viewModel.loadState else {
            Issue.record("expected .failed load state")
            return
        }
        #expect(viewModel.isEmpty == true)
    }
}
