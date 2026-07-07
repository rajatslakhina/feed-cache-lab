import Foundation

/// Abstraction over "fetch the bytes for this image URL", so the caching
/// layer above it can be tested against a fake instead of real networking.
public protocol ImageFetching: Sendable {
    func fetchImageData(for url: URL) async throws -> Data
}
