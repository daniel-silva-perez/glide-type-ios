import XCTest
@testable import GlideCore

final class SwipeDecoderTests: XCTestCase {
    private let keyCenters: [Character: GTPoint] = {
        let rows = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        var centers: [Character: GTPoint] = [:]
        for (rowIndex, row) in rows.enumerated() {
            let offset = rowIndex == 1 ? 0.5 : rowIndex == 2 ? 1.2 : 0.0
            for (columnIndex, char) in row.enumerated() {
                centers[char] = GTPoint(x: (Double(columnIndex) + offset) * 40.0, y: Double(rowIndex) * 48.0)
            }
        }
        return centers
    }()

    func testDecodesStraightforwardWord() {
        let decoder = SwipeDecoder(dictionary: ["the", "that", "there", "then"])
        let path = ["t", "h", "e"].compactMap { keyCenters[Character($0)] }
        let candidates = decoder.decode(path: path, keyCenters: keyCenters, limit: 3)
        XCTAssertEqual(candidates.first, "the")
    }

    func testUsesContextBoost() {
        let decoder = SwipeDecoder(dictionary: ["type", "time", "to"])
        let path = ["t", "y", "p", "e"].compactMap { keyCenters[Character($0)] }
        let candidates = decoder.decode(path: path, keyCenters: keyCenters, context: "slide to", limit: 3)
        XCTAssertEqual(candidates.first, "type")
    }
}
