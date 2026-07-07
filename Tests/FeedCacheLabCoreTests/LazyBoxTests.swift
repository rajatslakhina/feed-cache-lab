import Testing
@testable import FeedCacheLabCore

struct LazyBoxTests {
    @Test func factoryNotCalledUntilFirstAccess() {
        var factoryCalled = false
        let box = LazyBox<Int> {
            factoryCalled = true
            return 7
        }
        #expect(factoryCalled == false)
        #expect(box.hasBeenConstructed == false)
        #expect(box.constructionCount == 0)

        _ = box.value
        #expect(factoryCalled == true)
    }

    @Test func factoryInvokedExactlyOnceAcrossManyReads() {
        var callCount = 0
        let box = LazyBox<Int> {
            callCount += 1
            return callCount
        }

        let first = box.value
        let second = box.value
        let third = box.value

        #expect(first == 1)
        #expect(second == 1)
        #expect(third == 1)
        #expect(callCount == 1)
        #expect(box.constructionCount == 1)
    }

    @Test func hasBeenConstructedTransitionsCorrectly() {
        let box = LazyBox<String> { "constructed" }
        #expect(box.hasBeenConstructed == false)
        _ = box.value
        #expect(box.hasBeenConstructed == true)
    }

    @Test func independentBoxesDoNotShareState() {
        let boxA = LazyBox<Int> { 1 }
        let boxB = LazyBox<Int> { 2 }

        _ = boxA.value

        #expect(boxA.hasBeenConstructed == true)
        #expect(boxB.hasBeenConstructed == false)
        #expect(boxB.value == 2)
    }
}
