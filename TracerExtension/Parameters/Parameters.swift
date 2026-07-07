import Foundation
import AudioToolbox

let TracerParameterSpecs = ParameterTreeSpec {
    ParameterGroupSpec(identifier: "global", name: "Global") {
        ParameterSpec(
            address: .gateThreshold,
            identifier: "gateThreshold",
            name: "Gate Threshold",
            units: .decibels,
            valueRange: -80.0...0.0,
            defaultValue: -40.0
        )
        ParameterSpec(
            address: .sensitivity,
            identifier: "sensitivity",
            name: "Sensitivity",
            units: .generic,
            valueRange: 0.0...1.0,
            defaultValue: 0.5
        )
        ParameterSpec(
            address: .pitchBendEnable,
            identifier: "pitchBendEnable",
            name: "Pitch Bend",
            units: .boolean,
            valueRange: 0.0...1.0,
            defaultValue: 1.0
        )
    }
    ParameterGroupSpec(identifier: "meters", name: "Meters") {
        ParameterSpec(
            address: .detectedNote,
            identifier: "detectedNote",
            name: "Detected Note",
            units: .midiNoteNumber,
            valueRange: 0.0...127.0,
            defaultValue: 0.0,
            flags: [.flag_IsReadable, .flag_MeterReadOnly]
        )
        ParameterSpec(
            address: .detectedFrequency,
            identifier: "detectedFrequency",
            name: "Detected Frequency",
            units: .hertz,
            valueRange: 0.0...2000.0,
            defaultValue: 0.0,
            flags: [.flag_IsReadable, .flag_MeterReadOnly]
        )
        ParameterSpec(
            address: .noteActive,
            identifier: "noteActive",
            name: "Note Active",
            units: .boolean,
            valueRange: 0.0...1.0,
            defaultValue: 0.0,
            flags: [.flag_IsReadable, .flag_MeterReadOnly]
        )
    }
}

extension ParameterSpec {
    init(
        address: TracerParameterAddress,
        identifier: String,
        name: String,
        units: AudioUnitParameterUnit,
        valueRange: ClosedRange<AUValue>,
        defaultValue: AUValue,
        unitName: String? = nil,
        flags: AudioUnitParameterOptions = [AudioUnitParameterOptions.flag_IsWritable, AudioUnitParameterOptions.flag_IsReadable],
        valueStrings: [String]? = nil,
        dependentParameters: [NSNumber]? = nil
    ) {
        self.init(address: address.rawValue,
                  identifier: identifier,
                  name: name,
                  units: units,
                  valueRange: valueRange,
                  defaultValue: defaultValue,
                  unitName: unitName,
                  flags: flags,
                  valueStrings: valueStrings,
                  dependentParameters: dependentParameters)
    }
}
