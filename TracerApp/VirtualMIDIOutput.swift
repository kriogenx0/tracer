import CoreMIDI

/// Publishes a system-wide virtual CoreMIDI source named "Tracer" so any app
/// (Logic Pro, GarageBand, Ableton, etc.) can select it as a MIDI input
/// directly, without hosting the Tracer plugin itself. Lives for the whole
/// app session.
final class VirtualMIDIOutput {
    private var client = MIDIClientRef()
    private var source = MIDIEndpointRef()

    init(name: String) {
        MIDIClientCreateWithBlock(name as CFString, &client, nil)
        MIDISourceCreate(client, name as CFString, &source)
    }

    func send(_ bytes: [UInt8]) {
        guard source != 0, !bytes.isEmpty, bytes.count <= 256 else { return }

        var packetList = MIDIPacketList()
        let packet = MIDIPacketListInit(&packetList)
        _ = MIDIPacketListAdd(&packetList, MemoryLayout<MIDIPacketList>.size, packet, 0, bytes.count, bytes)
        MIDIReceived(source, &packetList)
    }

    deinit {
        if source != 0 { MIDIEndpointDispose(source) }
        if client != 0 { MIDIClientDispose(client) }
    }
}
