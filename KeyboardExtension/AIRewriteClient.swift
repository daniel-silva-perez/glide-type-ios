import Foundation

protocol AIRewriteClient {
    func rewrite(_ text: String, style: RewriteStyle) async throws -> String
}

enum RewriteStyle: String, CaseIterable {
    case clean
    case shorter
    case casual
    case professional
}

enum AIRewriteError: Error {
    case notConfigured
}

/// Safe default: no network calls from the keyboard.
/// Later, wire this to the containing app with an App Group, or add a user-triggered API call
/// only when Full Access is enabled and the user explicitly taps an AI action.
final class StubAIRewriteClient: AIRewriteClient {
    func rewrite(_ text: String, style: RewriteStyle) async throws -> String {
        throw AIRewriteError.notConfigured
    }
}
