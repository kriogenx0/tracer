import SwiftUI

/// A SwiftUI Slider container which is bound to an ObservableAUParameter
///
/// This view wraps a SwiftUI Slider, and provides it relevant data from the Parameter, like the minimum and maximum values.
struct ParameterSlider: View {
    @ObservedObject var param: ObservableAUParameter

    var specifier: String {
        switch param.unit {
        case .midiNoteNumber:
            return "%.0f"
        default:
            return "%.2f"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(param.displayName)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(param.value, specifier: specifier)")
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .font(.system(size: 11))
            .textSelection(.disabled)

            Slider(
                value: $param.value,
                in: param.min...param.max,
                onEditingChanged: param.onEditingChanged,
                minimumValueLabel: Text("\(param.min, specifier: specifier)"),
                maximumValueLabel: Text("\(param.max, specifier: specifier)")
            ) {
                EmptyView()
            }
            .font(.system(size: 10).monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibility(identifier: param.displayName)
        }
        .padding(.vertical, 4)
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
