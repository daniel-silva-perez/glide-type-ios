import UIKit

enum KeyboardAction: Equatable {
    case character(String)
    case shift
    case delete
    case space
    case returnKey
    case punctuation(String)
    case nextKeyboard
    case aiRewrite
    case switchNumbers
}

struct KeySpec {
    let title: String
    let action: KeyboardAction
    let weight: CGFloat
    let isLetter: Bool

    init(_ title: String, action: KeyboardAction, weight: CGFloat = 1, isLetter: Bool = false) {
        self.title = title
        self.action = action
        self.weight = weight
        self.isLetter = isLetter
    }
}
