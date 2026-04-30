import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    instructionCard
                    featureCard
                    privacyCard
                    roadmapCard
                }
                .padding(20)
            }
            .navigationTitle("GlideType")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Swipe faster. Edit smarter.")
                .font(.largeTitle.bold())
            Text("A privacy-first custom keyboard MVP with one-word glide typing, smart punctuation gestures, candidate replacement, and a safe AI rewrite placeholder.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var instructionCard: some View {
        Card(title: "Enable the keyboard") {
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Build and run this app on your iPhone.")
                Text("2. Open Settings → General → Keyboard → Keyboards → Add New Keyboard.")
                Text("3. Choose GlideType.")
                Text("4. Do not enable Full Access for the MVP. Swipe typing works offline.")
            }
        }
    }

    private var featureCard: some View {
        Card(title: "MVP gestures") {
            VStack(alignment: .leading, spacing: 8) {
                Text("• Glide across letters to insert the best word.")
                Text("• Tap candidate chips to replace the last swiped word.")
                Text("• Double-tap space behavior: space after space becomes period + space.")
                Text("• Swipe space left to delete the previous word.")
                Text("• Swipe space right for period, up for question mark.")
                Text("• Swipe the period key up for ?, right for !, left for comma.")
            }
        }
    }

    private var privacyCard: some View {
        Card(title: "Privacy posture") {
            Text("The extension sets RequestsOpenAccess to false. That means no network calls from the keyboard by default. The AI rewrite button is intentionally a stub until you add an explicit, opt-in rewrite flow.")
        }
    }

    private var roadmapCard: some View {
        Card(title: "Next build targets") {
            VStack(alignment: .leading, spacing: 8) {
                Text("• Larger local dictionary and personal words.")
                Text("• Core ML next-word ranking.")
                Text("• Sentence glide buffer.")
                Text("• Theming and haptics tuning.")
                Text("• Optional full-access AI rewrite with explicit consent.")
            }
        }
    }
}

private struct Card<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
                .font(.callout)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    ContentView()
}
