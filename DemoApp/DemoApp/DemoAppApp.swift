import SwiftUI
import FeedCacheLabUI

@main
struct DemoAppApp: App {
    var body: some Scene {
        WindowGroup {
            FeedListView(viewModel: DemoFactory.makeSampleFeedViewModel())
        }
    }
}
