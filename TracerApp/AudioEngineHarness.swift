import AVFoundation
import AudioToolbox

@MainActor
final class AudioEngineHarness: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var events: [DetectedNoteEvent] = []
    @Published private(set) var lastError: String?

    private let engine = AVAudioEngine()
    private var tracerUnit: AVAudioUnit?
    private let virtualMIDIOutput = VirtualMIDIOutput(name: "Tracer")

    func start() async {
        guard !isRunning else { return }
        lastError = nil

        do {
            let unit = try await resolveTracerUnit()

            let sampleRate = engine.inputNode.outputFormat(forBus: 0).sampleRate
            let monoFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

            engine.connect(engine.inputNode, to: unit, format: monoFormat)
            engine.connect(unit, to: engine.mainMixerNode, format: monoFormat)
            // Keep the graph connected (so Tracer is actually pulled/rendered) without
            // risking mic-to-speaker feedback.
            engine.mainMixerNode.outputVolume = 0

            engine.prepare()
            try engine.start()
            isRunning = true
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.stop()
        if let tracerUnit {
            engine.disconnectNodeInput(tracerUnit)
            engine.disconnectNodeOutput(tracerUnit)
        }
        isRunning = false
    }

    private func resolveTracerUnit() async throws -> AVAudioUnit {
        if let tracerUnit {
            return tracerUnit
        }

        var description = AudioComponentDescription()
        description.componentType = kAudioUnitType_MusicEffect
        description.componentSubType = FourCharCode("Trcr")
        description.componentManufacturer = FourCharCode("Trcr")

        let unit = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AVAudioUnit, Error>) in
            AVAudioUnit.instantiate(with: description, options: []) { avAudioUnit, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let avAudioUnit {
                    continuation.resume(returning: avAudioUnit)
                } else {
                    continuation.resume(throwing: CocoaError(.fileReadUnknown))
                }
            }
        }

        engine.attach(unit)
        setUpMIDIOutput(on: unit)
        tracerUnit = unit
        return unit
    }

    private func setUpMIDIOutput(on unit: AVAudioUnit) {
        unit.auAudioUnit.midiOutputEventBlock = { [weak self] _, _, length, midiBytes in
            guard length > 0 else { return noErr }
            let bytes = Array(UnsafeBufferPointer(start: midiBytes, count: length))
            DispatchQueue.main.async {
                self?.handleMIDI(bytes: bytes)
            }
            return noErr
        }
    }

    private func handleMIDI(bytes: [UInt8]) {
        virtualMIDIOutput.send(bytes)
        guard let event = DetectedNoteEvent(midiBytes: bytes) else { return }
        events.append(event)
        if events.count > 200 {
            events.removeFirst(events.count - 200)
        }
    }
}

private extension FourCharCode {
    init(_ string: StaticString) {
        precondition(string.utf8CodeUnitCount == 4)
        self = string.withUTF8Buffer { buffer in
            buffer.reduce(0) { ($0 << 8) + FourCharCode($1) }
        }
    }
}
