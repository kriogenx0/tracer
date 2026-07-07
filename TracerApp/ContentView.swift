import SwiftUI

struct ContentView: View {
    @StateObject private var harness = AudioEngineHarness()

    var body: some View {
        VStack(spacing: 16) {
            Text("Tracer")
                .font(.largeTitle.bold())
            Text("Sing or play a single note into the mic; Tracer emits the detected pitch as MIDI below.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Also available system-wide as MIDI source \u{201C}Tracer\u{201D} — select it as a MIDI input in Logic, GarageBand, Ableton, etc.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(harness.isRunning ? "Stop" : "Start") {
                Task {
                    if harness.isRunning {
                        harness.stop()
                    } else {
                        await harness.start()
                    }
                }
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            if let lastError = harness.lastError {
                Text(lastError)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Divider()

            Text("Recent MIDI events")
                .font(.headline)

            List(harness.events.reversed()) { event in
                Text(event.description)
                    .font(.system(.body, design: .monospaced))
            }
            .frame(minHeight: 200)
        }
        .padding()
        .frame(minWidth: 420, minHeight: 480)
    }
}
