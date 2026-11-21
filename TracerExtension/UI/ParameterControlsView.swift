import SwiftUI

struct ParameterControlsView: View {
    var parameterTree: ObservableAUParameterGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ParameterKnob(param: parameterTree.global.gateThreshold)
                ParameterKnob(param: parameterTree.global.sensitivity)
            }
            ParameterToggle(param: parameterTree.global.pitchBendEnable)
        }
    }
}
