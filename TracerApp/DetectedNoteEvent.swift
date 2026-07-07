import Foundation

struct DetectedNoteEvent: Identifiable {
    enum Kind {
        case noteOn
        case noteOff
        case pitchBend
    }

    let id = UUID()
    let kind: Kind
    let note: UInt8
    let velocity: UInt8
    let bend14: UInt16
    let timestamp: Date

    init?(midiBytes: [UInt8]) {
        guard midiBytes.count >= 3 else { return nil }

        switch midiBytes[0] & 0xF0 {
        case 0x90:
            kind = .noteOn
            note = midiBytes[1]
            velocity = midiBytes[2]
            bend14 = 8192
        case 0x80:
            kind = .noteOff
            note = midiBytes[1]
            velocity = 0
            bend14 = 8192
        case 0xE0:
            kind = .pitchBend
            note = 0
            velocity = 0
            bend14 = UInt16(midiBytes[1] & 0x7F) | (UInt16(midiBytes[2] & 0x7F) << 7)
        default:
            return nil
        }

        timestamp = Date()
    }

    var noteName: String {
        let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let n = Int(note)
        let octave = n / 12 - 1
        let name = names[((n % 12) + 12) % 12]
        return "\(name)\(octave)"
    }

    var description: String {
        switch kind {
        case .noteOn:
            return "Note On   \(noteName)   vel \(velocity)"
        case .noteOff:
            return "Note Off  \(noteName)"
        case .pitchBend:
            let cents = (Double(bend14) - 8192.0) / 8191.0 * 100.0
            return String(format: "Bend      %+.0f cents", cents)
        }
    }
}
