import Foundation
import Testing
@testable import FeedCacheLabCore

struct RowConstructionTrackerTests {
    @Test func countIsZeroBeforeAnyRecording() {
        let tracker = RowConstructionTracker()
        let id = UUID()
        #expect(tracker.count(for: id) == 0)
        #expect(tracker.maxConstructionCount == 0)
    }

    @Test func recordsPerIdIndependently() {
        let tracker = RowConstructionTracker()
        let idA = UUID()
        let idB = UUID()

        tracker.recordConstruction(for: idA)
        tracker.recordConstruction(for: idA)
        tracker.recordConstruction(for: idB)

        #expect(tracker.count(for: idA) == 2)
        #expect(tracker.count(for: idB) == 1)
        #expect(tracker.maxConstructionCount == 2)
    }

    @Test func maxConstructionCountOnEmptyTrackerIsZeroNotCrash() {
        let tracker = RowConstructionTracker()
        // No entries at all yet -- `.max()` on an empty collection must not
        // be force-unwrapped; this asserts the nil-coalescing fallback path.
        #expect(tracker.maxConstructionCount == 0)
    }
}
