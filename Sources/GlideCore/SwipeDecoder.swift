import Foundation

public struct SwipeCandidate: Equatable, Sendable {
    public let word: String
    public let score: Double
}

public final class SwipeDecoder: @unchecked Sendable {
    private let dictionary: [String]
    private let languageModel: LanguageModel

    public init(dictionary: [String] = BuiltInEnglishWords.words, languageModel: LanguageModel = LanguageModel()) {
        self.dictionary = Array(Set(dictionary.map { $0.lowercased() })).sorted()
        self.languageModel = languageModel
    }

    public func decode(
        path rawPath: [GTPoint],
        keyCenters: [Character: GTPoint],
        context: String? = nil,
        limit: Int = 5
    ) -> [String] {
        rankedCandidates(path: rawPath, keyCenters: keyCenters, context: context, limit: limit).map(\.word)
    }

    public func rankedCandidates(
        path rawPath: [GTPoint],
        keyCenters: [Character: GTPoint],
        context: String? = nil,
        limit: Int = 5
    ) -> [SwipeCandidate] {
        guard rawPath.count >= 3, !keyCenters.isEmpty else { return [] }
        let path = simplify(rawPath)
        let signature = nearestSignature(for: path, keyCenters: keyCenters)
        guard signature.count >= 1 else { return [] }

        let previous = languageModel.previousWord(from: context)
        let ranked = dictionary.compactMap { word -> SwipeCandidate? in
            let letters = Array(word)
            guard let first = letters.first, let last = letters.last else { return nil }
            guard keyCenters[first] != nil, keyCenters[last] != nil else { return nil }
            guard word.count <= 18 else { return nil }

            let score = candidateScore(
                word: word,
                letters: letters,
                path: path,
                signature: signature,
                keyCenters: keyCenters,
                previousWord: previous
            )
            guard score > 0.15 else { return nil }
            return SwipeCandidate(word: word, score: score)
        }

        return ranked
            .sorted { lhs, rhs in
                if abs(lhs.score - rhs.score) < 0.001 { return lhs.word.count < rhs.word.count }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map { $0 }
    }

    private func candidateScore(
        word: String,
        letters: [Character],
        path: [GTPoint],
        signature: [Character],
        keyCenters: [Character: GTPoint],
        previousWord: String?
    ) -> Double {
        var score = 0.0

        if signature.first == letters.first { score += 2.0 }
        if signature.last == letters.last { score += 2.0 }

        let sequence = sequenceAlignmentScore(wordLetters: letters, signature: signature)
        score += sequence * 4.0

        let shape = shapeScore(wordLetters: letters, path: path, keyCenters: keyCenters)
        score += shape * 5.0

        let lengthPenalty = abs(Double(signature.count - letters.count)) * 0.12
        score -= lengthPenalty

        score += languageModel.contextBoost(for: word, previousWord: previousWord)
        return score
    }

    private func sequenceAlignmentScore(wordLetters: [Character], signature: [Character]) -> Double {
        guard !wordLetters.isEmpty, !signature.isEmpty else { return 0 }
        var index = 0
        var hits = 0
        for letter in wordLetters {
            while index < signature.count && signature[index] != letter {
                index += 1
            }
            if index < signature.count {
                hits += 1
                index += 1
            }
        }
        let coverage = Double(hits) / Double(wordLetters.count)
        let firstLastBonus = (signature.first == wordLetters.first ? 0.15 : 0) + (signature.last == wordLetters.last ? 0.15 : 0)
        return min(1.0, coverage + firstLastBonus)
    }

    private func shapeScore(wordLetters: [Character], path: [GTPoint], keyCenters: [Character: GTPoint]) -> Double {
        let template = wordLetters.compactMap { keyCenters[$0] }
        guard template.count == wordLetters.count, template.count > 1 else { return 0.2 }

        let sampleCount = 24
        let normalizedPath = path.resampled(to: sampleCount).normalized()
        let normalizedTemplate = template.resampled(to: sampleCount).normalized()
        let distance = zip(normalizedPath, normalizedTemplate).reduce(0.0) { partial, pair in
            partial + pair.0.distance(to: pair.1)
        } / Double(sampleCount)

        return max(0.0, 1.0 - distance)
    }

    private func nearestSignature(for path: [GTPoint], keyCenters: [Character: GTPoint]) -> [Character] {
        var result: [Character] = []
        for point in path {
            guard let nearest = keyCenters.min(by: { lhs, rhs in
                lhs.value.distance(to: point) < rhs.value.distance(to: point)
            })?.key else { continue }
            if result.last != nearest { result.append(nearest) }
        }
        return collapseRepeatedNoise(result)
    }

    private func collapseRepeatedNoise(_ letters: [Character]) -> [Character] {
        guard letters.count > 2 else { return letters }
        var cleaned: [Character] = []
        for letter in letters {
            if cleaned.suffix(2).allSatisfy({ $0 == letter }) { continue }
            if cleaned.last != letter { cleaned.append(letter) }
        }
        return cleaned
    }

    private func simplify(_ path: [GTPoint]) -> [GTPoint] {
        guard let first = path.first else { return [] }
        var simplified = [first]
        for point in path.dropFirst() {
            if point.distance(to: simplified.last!) > 6.0 {
                simplified.append(point)
            }
        }
        return simplified
    }
}
