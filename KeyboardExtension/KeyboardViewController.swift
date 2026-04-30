import UIKit
import GlideCore

final class KeyboardViewController: UIInputViewController {
    private let keyboardView = GlideKeyboardView()
    private let decoder = SwipeDecoder()
    private let inputEngine = KeyboardInputEngine()
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureKeyboard()
    }

    private func configureKeyboard() {
        keyboardView.delegate = self
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardView)

        let height = view.heightAnchor.constraint(equalToConstant: 306)
        height.priority = .defaultHigh

        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            height
        ])
    }

    private func convert(_ point: CGPoint) -> GTPoint {
        GTPoint(x: Double(point.x), y: Double(point.y))
    }
}

extension KeyboardViewController: GlideKeyboardViewDelegate {
    func keyboardView(_ view: GlideKeyboardView, didTap action: KeyboardAction) {
        feedback.impactOccurred(intensity: 0.45)
        switch action {
        case .nextKeyboard:
            advanceToNextInputMode()
        case .aiRewrite:
            // MVP behavior: make the AI control visible but safe.
            // Later: open app group settings or call a user-triggered rewrite flow.
            keyboardView.showCandidates(["clean", "shorter", "casual", "pro"])
        default:
            inputEngine.handle(action, proxy: textDocumentProxy)
        }
    }

    func keyboardView(_ view: GlideKeyboardView, didFinishSwipe points: [CGPoint], keyCenters: [Character: CGPoint]) {
        let convertedPath = points.map(convert)
        let convertedCenters = keyCenters.mapValues(convert)
        let candidates = decoder.decode(
            path: convertedPath,
            keyCenters: convertedCenters,
            context: textDocumentProxy.documentContextBeforeInput,
            limit: 4
        )

        guard let best = candidates.first else { return }
        feedback.impactOccurred(intensity: 0.75)
        inputEngine.commitSwipeWord(best, proxy: textDocumentProxy)
        keyboardView.showCandidates(candidates)
    }

    func keyboardView(_ view: GlideKeyboardView, didChooseCandidate candidate: String) {
        switch candidate {
        case "clean", "shorter", "casual", "pro":
            textDocumentProxy.insertText("[")
            textDocumentProxy.insertText(candidate)
            textDocumentProxy.insertText(" rewrite not configured]")
        default:
            inputEngine.replaceLastSwipeWord(with: candidate, proxy: textDocumentProxy)
        }
    }

    func keyboardViewDidRequestNextKeyboard(_ view: GlideKeyboardView) {
        advanceToNextInputMode()
    }

    func keyboardViewDidRequestDeleteWord(_ view: GlideKeyboardView) {
        inputEngine.deletePreviousWord(proxy: textDocumentProxy)
    }
}
