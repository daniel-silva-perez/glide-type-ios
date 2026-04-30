import UIKit

protocol GlideKeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: GlideKeyboardView, didTap action: KeyboardAction)
    func keyboardView(_ view: GlideKeyboardView, didFinishSwipe points: [CGPoint], keyCenters: [Character: CGPoint])
    func keyboardView(_ view: GlideKeyboardView, didChooseCandidate candidate: String)
    func keyboardViewDidRequestNextKeyboard(_ view: GlideKeyboardView)
    func keyboardViewDidRequestDeleteWord(_ view: GlideKeyboardView)
}

final class GlideKeyboardView: UIView {
    weak var delegate: GlideKeyboardViewDelegate?

    private let rootStack = UIStackView()
    private let candidateStack = UIStackView()
    private let rowsStack = UIStackView()
    private var letterButtons: [Character: UIButton] = [:]
    private var buttonActions: [UIButton: KeyboardAction] = [:]
    private var swipePoints: [CGPoint] = []
    private var didSwipe = false

    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        recognizer.cancelsTouchesInView = false
        recognizer.maximumNumberOfTouches = 1
        return recognizer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildInterface()
        addGestureRecognizer(panRecognizer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildInterface()
        addGestureRecognizer(panRecognizer)
    }

    func showCandidates(_ candidates: [String]) {
        candidateStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let items = candidates.isEmpty ? ["AI", "?", "!", ","] : candidates
        for item in items.prefix(4) {
            let button = makeCandidateButton(title: item)
            candidateStack.addArrangedSubview(button)
        }
    }

    var currentLetterCenters: [Character: CGPoint] {
        var centers: [Character: CGPoint] = [:]
        for (letter, button) in letterButtons {
            centers[letter] = button.convert(CGPoint(x: button.bounds.midX, y: button.bounds.midY), to: self)
        }
        return centers
    }

    private func buildInterface() {
        backgroundColor = UIColor.systemGray6

        rootStack.axis = .vertical
        rootStack.alignment = .fill
        rootStack.distribution = .fill
        rootStack.spacing = 6
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        candidateStack.axis = .horizontal
        candidateStack.distribution = .fillEqually
        candidateStack.alignment = .fill
        candidateStack.spacing = 6
        candidateStack.heightAnchor.constraint(equalToConstant: 38).isActive = true
        rootStack.addArrangedSubview(candidateStack)

        rowsStack.axis = .vertical
        rowsStack.distribution = .fillEqually
        rowsStack.alignment = .fill
        rowsStack.spacing = 7
        rootStack.addArrangedSubview(rowsStack)

        buildRows()
        showCandidates([])
    }

    private func buildRows() {
        let rows: [[KeySpec]] = [
            "qwertyuiop".map { KeySpec(String($0), action: .character(String($0)), isLetter: true) },
            "asdfghjkl".map { KeySpec(String($0), action: .character(String($0)), isLetter: true) },
            [KeySpec("⇧", action: .shift, weight: 1.25)] + "zxcvbnm".map { KeySpec(String($0), action: .character(String($0)), isLetter: true) } + [KeySpec("⌫", action: .delete, weight: 1.25)],
            [
                KeySpec("🌐", action: .nextKeyboard, weight: 0.9),
                KeySpec("AI", action: .aiRewrite, weight: 0.9),
                KeySpec("space", action: .space, weight: 4.0),
                KeySpec(".", action: .punctuation("."), weight: 0.9),
                KeySpec("↵", action: .returnKey, weight: 1.1)
            ]
        ]

        for row in rows {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.alignment = .fill
            stack.distribution = .fillProportionally
            stack.spacing = 5
            rowsStack.addArrangedSubview(stack)

            for spec in row {
                let button = makeKeyButton(spec)
                stack.addArrangedSubview(button)
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: 28 * spec.weight).isActive = true
                if spec.isLetter, let letter = spec.title.first {
                    letterButtons[letter] = button
                }
            }
        }
    }

    private func makeKeyButton(_ spec: KeySpec) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(spec.title, for: .normal)
        button.titleLabel?.font = spec.isLetter ? .systemFont(ofSize: 22, weight: .regular) : .systemFont(ofSize: 16, weight: .semibold)
        button.tintColor = .label
        button.backgroundColor = spec.isLetter ? .systemBackground : .secondarySystemBackground
        button.layer.cornerRadius = 7
        button.layer.masksToBounds = true
        buttonActions[button] = spec.action
        button.addAction(UIAction { [weak self, weak button] _ in
            guard let self, let button, !self.didSwipe, let action = self.buttonActions[button] else { return }
            if action == .nextKeyboard {
                self.delegate?.keyboardViewDidRequestNextKeyboard(self)
            } else {
                self.delegate?.keyboardView(self, didTap: action)
            }
        }, for: .touchUpInside)

        if spec.action == .space {
            addSpaceGestures(to: button)
        }
        if case .punctuation = spec.action {
            addPunctuationGestures(to: button)
        }
        return button
    }

    private func makeCandidateButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.tintColor = .label
        button.backgroundColor = .tertiarySystemBackground
        button.layer.cornerRadius = 8
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            switch title {
            case "?", "!", ",":
                self.delegate?.keyboardView(self, didTap: .punctuation(title))
            case "AI":
                self.delegate?.keyboardView(self, didTap: .aiRewrite)
            default:
                self.delegate?.keyboardView(self, didChooseCandidate: title)
            }
        }, for: .touchUpInside)
        return button
    }

    private func addSpaceGestures(to button: UIButton) {
        addSwipe(to: button, direction: .left, selector: #selector(handleSpaceSwipe(_:)))
        addSwipe(to: button, direction: .right, selector: #selector(handleSpaceSwipe(_:)))
        addSwipe(to: button, direction: .up, selector: #selector(handleSpaceSwipe(_:)))
    }

    private func addPunctuationGestures(to button: UIButton) {
        addSwipe(to: button, direction: .up, selector: #selector(handlePunctuationSwipe(_:)))
        addSwipe(to: button, direction: .right, selector: #selector(handlePunctuationSwipe(_:)))
        addSwipe(to: button, direction: .left, selector: #selector(handlePunctuationSwipe(_:)))
    }

    private func addSwipe(to view: UIView, direction: UISwipeGestureRecognizer.Direction, selector: Selector) {
        let swipe = UISwipeGestureRecognizer(target: self, action: selector)
        swipe.direction = direction
        view.addGestureRecognizer(swipe)
    }

    @objc private func handleSpaceSwipe(_ recognizer: UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case .left:
            delegate?.keyboardViewDidRequestDeleteWord(self)
        case .right:
            delegate?.keyboardView(self, didTap: .punctuation("."))
        case .up:
            delegate?.keyboardView(self, didTap: .punctuation("?"))
        default:
            break
        }
    }

    @objc private func handlePunctuationSwipe(_ recognizer: UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case .up:
            delegate?.keyboardView(self, didTap: .punctuation("?"))
        case .right:
            delegate?.keyboardView(self, didTap: .punctuation("!"))
        case .left:
            delegate?.keyboardView(self, didTap: .punctuation(","))
        default:
            break
        }
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            didSwipe = false
            swipePoints = [location]
        case .changed:
            swipePoints.append(location)
            if swipePoints.count > 4 { didSwipe = true }
        case .ended, .cancelled, .failed:
            let points = swipePoints
            swipePoints.removeAll()
            defer { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.didSwipe = false } }
            guard didSwipe, points.count > 4 else { return }
            delegate?.keyboardView(self, didFinishSwipe: points, keyCenters: currentLetterCenters)
        default:
            break
        }
    }
}
