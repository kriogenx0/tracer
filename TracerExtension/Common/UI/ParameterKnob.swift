import AudioToolbox
import SwiftUI
import VoltaNative

/// A Volta knob bound to an ObservableAUParameter.
///
/// The knob's range, default and unit all come from the parameter itself
/// (see Parameters.swift), so the UI never repeats them.
struct ParameterKnob: View {
    @ObservedObject var param: ObservableAUParameter

    var body: some View {
        VoltaKnob(param.displayName, spec: spec, value: Binding(
            get: { Double(param.value) },
            set: { param.value = AUValue($0) }
        ))
    }

    private var spec: KnobSpec {
        let range = Double(param.min)...Double(param.max)
        let step = (range.upperBound - range.lowerBound) / 100
        switch param.unit {
        case .decibels:
            return KnobSpec(range: range, defaultValue: Double(param.defaultValue), step: 1, unitSuffix: " dB")
        case .percent:
            return KnobSpec(range: range, defaultValue: Double(param.defaultValue), step: 1, unitSuffix: "%")
        case .hertz:
            return KnobSpec(range: range, defaultValue: Double(param.defaultValue), step: step, unitSuffix: " Hz")
        case .midiNoteNumber:
            return KnobSpec(range: range, defaultValue: Double(param.defaultValue), step: 1)
        default:
            // Generic 0...1 values read best as a percentage.
            let isUnit = range == 0...1
            return KnobSpec(range: range, defaultValue: Double(param.defaultValue), step: step,
                            displayScale: isUnit ? 100 : 1, unitSuffix: isUnit ? "%" : "")
        }
    }
}

/// A SwiftUI Toggle container which is bound to a boolean-valued ObservableAUParameter
struct ParameterToggle: View {
    @ObservedObject var param: ObservableAUParameter

    var body: some View {
        Toggle(param.displayName, isOn: $param.boolValue)
            .font(.system(size: 12))
    }
}
