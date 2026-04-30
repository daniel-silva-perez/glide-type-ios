import Foundation

public struct GTPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func distance(to other: GTPoint) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

extension Array where Element == GTPoint {
    func resampled(to targetCount: Int) -> [GTPoint] {
        guard targetCount > 1, count > 1 else { return self }
        let total = zip(self, self.dropFirst()).reduce(0.0) { partial, pair in
            partial + pair.0.distance(to: pair.1)
        }
        guard total > 0 else { return Array(repeating: self[0], count: targetCount) }

        let step = total / Double(targetCount - 1)
        var result: [GTPoint] = [self[0]]
        var accumulated = 0.0
        var previous = self[0]
        var remainingPoints = Array(self.dropFirst())

        while !remainingPoints.isEmpty && result.count < targetCount {
            let current = remainingPoints[0]
            let distance = previous.distance(to: current)
            if accumulated + distance >= step {
                let ratio = (step - accumulated) / max(distance, 0.000001)
                let interpolated = GTPoint(
                    x: previous.x + ratio * (current.x - previous.x),
                    y: previous.y + ratio * (current.y - previous.y)
                )
                result.append(interpolated)
                previous = interpolated
                accumulated = 0
            } else {
                accumulated += distance
                previous = current
                remainingPoints.removeFirst()
            }
        }

        while result.count < targetCount {
            result.append(self.last!)
        }
        return result
    }

    func normalized() -> [GTPoint] {
        guard !isEmpty else { return [] }
        let minX = map(\.x).min() ?? 0
        let maxX = map(\.x).max() ?? 1
        let minY = map(\.y).min() ?? 0
        let maxY = map(\.y).max() ?? 1
        let width = max(maxX - minX, 1.0)
        let height = max(maxY - minY, 1.0)
        let scale = max(width, height)
        return map { point in
            GTPoint(x: (point.x - minX) / scale, y: (point.y - minY) / scale)
        }
    }
}
