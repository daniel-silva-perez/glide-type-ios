# GlideTypeAI Spec

## One-liner

A privacy-first iOS keyboard that combines glide typing, candidate correction, punctuation gestures, and opt-in AI rewriting.

## Target user

Power users who want faster sentence-level input without constantly switching keyboard modes for punctuation, capitalization, and rewrites.

## MVP scope

The first version focuses on proving the input mechanic:

- Custom iOS keyboard extension.
- Offline one-word swipe decoder.
- Candidate correction row.
- Smart punctuation gestures.
- Auto-capitalization.
- Safe AI placeholder.

## Non-goals

- Reusing Apple's QuickType or Slide-to-Type engine.
- Collecting keystrokes.
- Sending typed text to a server by default.
- Replacing password/secure input behavior.

## Input model

### Tap typing

Tap keys insert characters through `UITextDocumentProxy`.

### Glide typing

The keyboard records touch points during a pan gesture. The decoder:

1. Maps touch points to nearest key centers.
2. Collapses duplicate/noisy key hits into a signature.
3. Scores dictionary words by:
   - first/last letter match,
   - sequence alignment,
   - normalized geometric shape distance,
   - previous-word context boost.
4. Commits the top candidate.
5. Keeps alternate candidates available for replacement.

### Punctuation gestures

- Space left: delete previous word.
- Space right: period.
- Space up: question mark.
- Period key up: question mark.
- Period key right: exclamation mark.
- Period key left: comma.

## AI rewrite model

The MVP intentionally does not send data anywhere. Future implementation should keep the rewrite flow explicit:

- User taps AI.
- Keyboard shows rewrite modes.
- App/extension previews text to send.
- User confirms.
- Only the selected context is sent.

## File map

```text
App/
  GlideTypeAIApp.swift      # Container app entry
  ContentView.swift         # Setup/roadmap screen
KeyboardExtension/
  KeyboardViewController.swift
  GlideKeyboardView.swift
  KeyboardInputEngine.swift
  KeyboardAction.swift
  AIRewriteClient.swift
Sources/GlideCore/
  SwipeDecoder.swift
  LanguageModel.swift
  Geometry.swift
  BuiltInEnglishWords.swift
Tests/GlideCoreTests/
  SwipeDecoderTests.swift
project.yml                 # XcodeGen project definition
```
