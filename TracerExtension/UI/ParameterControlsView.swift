import SwiftUI

struct ParameterControlsView: View {
    var parameterTree: ObservableAUParameterGroup

    var body: some View {
        VStack {
            ParameterSlider(param: parameterTree.global.gateThreshold)
            ParameterSlider(param: parameterTree.global.sensitivity)
            ParameterToggle(param: parameterTree.global.pitchBendEnable)
        }
    }
}
