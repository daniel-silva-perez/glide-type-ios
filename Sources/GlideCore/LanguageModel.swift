import Foundation

public struct LanguageModel: Sendable {
    private let bigrams: [String: [String: Double]]

    public init() {
        self.bigrams = [
            "i": ["am": 2.8, "want": 2.4, "think": 2.2, "can": 2.0, "will": 1.8, "have": 1.6, "need": 1.6, "dont": 1.4],
            "you": ["can": 2.3, "should": 2.1, "want": 1.9, "know": 1.8, "have": 1.6],
            "we": ["can": 2.6, "should": 2.3, "need": 2.0, "could": 1.8, "have": 1.5],
            "can": ["you": 2.6, "we": 2.2, "i": 1.6],
            "could": ["you": 2.4, "we": 2.1, "i": 1.6],
            "what": ["is": 2.5, "are": 2.0, "about": 1.7],
            "how": ["do": 2.5, "does": 2.0, "can": 1.9, "about": 1.4],
            "the": ["app": 1.8, "keyboard": 1.8, "best": 1.6, "same": 1.4],
            "a": ["better": 2.0, "custom": 1.8, "new": 1.6, "real": 1.5],
            "build": ["it": 2.4, "a": 1.8, "the": 1.4],
            "slide": ["to": 3.0],
            "to": ["type": 2.4, "the": 1.5, "a": 1.3, "go": 1.6, "make": 1.6],
            "type": ["keyboard": 1.9, "whole": 1.8, "sentence": 1.6],
            "swift": ["keyboard": 1.8, "keys": 1.7]
        ]
    }

    public func contextBoost(for word: String, previousWord: String?) -> Double {
        guard let previousWord else { return 0 }
        return bigrams[previousWord.lowercased()]?[word.lowercased()] ?? 0
    }

    public func previousWord(from context: String?) -> String? {
        guard let context, !context.isEmpty else { return nil }
        let separators = CharacterSet.alphanumerics.inverted
        return context
            .lowercased()
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
            .last
    }
}
