import SwiftUI
import FeedCacheLabCore

struct MetricsOverlayView: View {
    let metrics: CacheMetrics
    let maxRowConstructions: Int

    var body: some View {
        HStack {
            metricLabel("Cache hits", value: metrics.hits)
            metricLabel("Cache misses", value: metrics.misses)
            metricLabel("Hit rate", value: Int((metrics.hitRate * 100).rounded()), suffix: "%")
            metricLabel("Max row inits", value: maxRowConstructions)
        }
        .font(.caption.monospacedDigit())
        .padding(8)
        .background(.thinMaterial)
    }

    private func metricLabel(_ title: String, value: Int, suffix: String = "") -> some View {
        VStack {
            Text("\(value)\(suffix)")
                .fontWeight(.semibold)
            Text(title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
