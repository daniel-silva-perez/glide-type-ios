import UIKit

final class KeyboardInputEngine {
    private var shiftEnabled = false
    private var lastSwipeCommitLength: Int?

    func handle(_ action: KeyboardAction, proxy: UITextDocumentProxy) {
        switch action {
        case .character(let value):
            insertCharacter(value, proxy: proxy)
        case .shift:
            shiftEnabled.toggle()
        case .delete:
            proxy.deleteBackward()
            lastSwipeCommitLength = nil
        case .space:
            insertSmartSpace(proxy: proxy)
        case .returnKey:
            proxy.insertText("\n")
            lastSwipeCommitLength = nil
        case .punctuation(let punctuation):
            insertPunctuation(punctuation, proxy: proxy)
        case .nextKeyboard, .aiRewrite, .switchNumbers:
            break
        }
    }

    func commitSwipeWord(_ word: String, proxy: UITextDocumentProxy) {
        let transformed = transformedWord(word, proxy: proxy)
        proxy.insertText(transformed + " ")
        lastSwipeCommitLength = transformed.count + 1
        shiftEnabled = false
    }

    func replaceLastSwipeWord(with word: String, proxy: UITextDocumentProxy) {
        guard let length = lastSwipeCommitLength else {
            commitSwipeWord(word, proxy: proxy)
            return
        }
        for _ in 0..<length { proxy.deleteBackward() }
        commitSwipeWord(word, proxy: proxy)
    }

    func deletePreviousWord(proxy: UITextDocumentProxy) {
        guard let context = proxy.documentContextBeforeInput, !context.isEmpty else {
            proxy.deleteBackward()
            return
        }
        var deleted = 0
        for char in context.reversed() {
            if deleted > 0 && char.isWhitespace { break }
            proxy.deleteBackward()
            deleted += 1
        }
        lastSwipeCommitLength = nil
    }

    private func insertCharacter(_ value: String, proxy: UITextDocumentProxy) {
        let output: String
        if shiftEnabled || shouldCapitalizeNext(proxy: proxy) {
            output = value.uppercased()
        } else {
            output = value.lowercased()
        }
        proxy.insertText(output)
        shiftEnabled = false
        lastSwipeCommitLength = nil
    }

    private func insertSmartSpace(proxy: UITextDocumentProxy) {
        let context = proxy.documentContextBeforeInput ?? ""
        if context.hasSuffix("  ") { return }
        if context.hasSuffix(" ") {
            proxy.deleteBackward()
            proxy.insertText(". ")
        } else {
            proxy.insertText(" ")
        }
        lastSwipeCommitLength = nil
    }

    private func insertPunctuation(_ punctuation: String, proxy: UITextDocumentProxy) {
        let context = proxy.documentContextBeforeInput ?? ""
        if context.hasSuffix(" ") {
            proxy.deleteBackward()
        }
        proxy.insertText(punctuation + " ")
        lastSwipeCommitLength = nil
    }

    private func transformedWord(_ word: String, proxy: UITextDocumentProxy) -> String {
        guard shouldCapitalizeNext(proxy: proxy), let first = word.first else { return word.lowercased() }
        return first.uppercased() + word.dropFirst().lowercased()
    }

    private func shouldCapitalizeNext(proxy: UITextDocumentProxy) -> Bool {
        let context = proxy.documentContextBeforeInput ?? ""
        let trimmed = context.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = trimmed.last else { return true }
        return ".!?".contains(last)
    }
}
