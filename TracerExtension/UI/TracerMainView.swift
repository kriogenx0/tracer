import SwiftUI

struct TracerMainView: View {
    var parameterTree: ObservableAUParameterGroup
    let rawParameterTree: AUParameterTree

    var body: some View {
        VStack(spacing: 16) {
            PitchReadoutView(parameterTree: rawParameterTree)
            Divider()
            ParameterControlsView(parameterTree: parameterTree)
        }
        .padding()
        .frame(minWidth: 320, minHeight: 320)
    }
}
