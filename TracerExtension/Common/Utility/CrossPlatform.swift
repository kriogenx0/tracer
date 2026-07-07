import Foundation
import SwiftUI

typealias HostingController = NSHostingController

extension NSView {
    // AppKit has no UIKit-style subview z-order API; SwiftUI-hosted content
    // here is always the sole subview, so reordering it is unnecessary.
    func bringSubviewToFront(_ view: NSView) {}
}
