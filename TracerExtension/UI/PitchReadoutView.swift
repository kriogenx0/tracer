import SwiftUI
import AudioToolbox

/// Polls the kernel's read-only meter parameters on a timer and shows the
/// currently detected note. These are MeterReadOnly AUParameters, updated on
/// the render thread every analysis hop — there's no push notification for
/// them, so the UI has to pull.
struct PitchReadoutView: View {
    let parameterTree: AUParameterTree

    @State private var noteActive = false
    @State private var detectedNote: Float = 0
    @State private var detectedFrequency: Float = 0

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            Text(noteActive ? noteName(for: detectedNote) : "—")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text(noteActive ? String(format: "%.1f Hz", detectedFrequency) : "No pitch detected")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .onAppear(perform: refresh)
        .onReceive(timer) { _ in refresh() }
    }

    private func refresh() {
        guard
            let activeParam = parameterTree.parameter(withAddress: TracerParameterAddress.noteActive.rawValue),
            let noteParam = parameterTree.parameter(withAddress: TracerParameterAddress.detectedNote.rawValue),
            let freqParam = parameterTree.parameter(withAddress: TracerParameterAddress.detectedFrequency.rawValue)
        else { return }

        noteActive = activeParam.value >= 0.5
        detectedNote = noteParam.value
        detectedFrequency = freqParam.value
    }

    private func noteName(for midiNote: Float) -> String {
        let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let note = Int(midiNote.rounded())
        let octave = note / 12 - 1
        let name = names[((note % 12) + 12) % 12]
        return "\(name)\(octave)"
    }
}
