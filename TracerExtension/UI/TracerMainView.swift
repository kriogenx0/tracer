import SwiftUI
import VoltaNative

struct TracerMainView: View {
    var parameterTree: ObservableAUParameterGroup
    let rawParameterTree: AUParameterTree
    @Environment(\.voltaAccent) private var accent

    var body: some View {
        VStack(spacing: 16) {
            PitchReadoutView(parameterTree: rawParameterTree)
            VoltaDivider()
            ParameterControlsView(parameterTree: parameterTree)
        }
        .padding(16)
        .frame(minWidth: 320, minHeight: 320)
        .background(Color.voltaCanvas)
        .voltaControls()
        .tint(accent)
    }
}
