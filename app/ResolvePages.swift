// v23 (Marko, 31.10.2026: "I want the G-keys to control something ... Each key should invoke a module of DaVinci Resolve,
// in the order in which they are shown on the user interface. Pressing the number 1 will trigger number 1, then number 2 ...
// If I change how many there are, it should also change what it triggers"): while DaVinci Resolve is the front app, G1–G5
// press the n-th button of Resolve's page bar. The bar is read live through Accessibility each time (AXCheckBox Media,
// Photo, Cut, Edit, Fusion, Color, Fairlight, Deliver along the bottom, ordered by x), so a page Marko hides in Workspace >
// Show Page drops out and every key after it moves up. Elsewhere G1–G5 play their macros as before.
import AppKit
import ApplicationServices

enum ResolvePages {
    static let bundle = "com.blackmagic-design.DaVinciResolve"
    static let names: Set<String> = ["Media", "Photo", "Cut", "Edit", "Fusion", "Color", "Fairlight", "Deliver"]

    static var resolveInFront: Bool { NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundle }

    private static func attr(_ e: AXUIElement, _ a: String) -> CFTypeRef? {
        var v: CFTypeRef?; return AXUIElementCopyAttributeValue(e, a as CFString, &v) == .success ? v : nil
    }

    /// the page bar's buttons, left to right
    static func pageBar() -> [(name: String, el: AXUIElement)] {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundle).first else { return [] }
        let ax = AXUIElementCreateApplication(app.processIdentifier)
        var found: [(String, AXUIElement, CGFloat)] = []
        func walk(_ e: AXUIElement, _ d: Int) {
            if d > 25 || found.count >= 8 { return }
            if (attr(e, kAXRoleAttribute) as? String) == "AXCheckBox",
               let t = (attr(e, kAXDescriptionAttribute) as? String) ?? (attr(e, kAXTitleAttribute) as? String), names.contains(t) {
                var p = CGPoint.zero
                if let v = attr(e, kAXPositionAttribute) { AXValueGetValue(v as! AXValue, .cgPoint, &p) }
                found.append((t, e, p.x))
            }
            for c in (attr(e, kAXChildrenAttribute) as? [AXUIElement]) ?? [] { walk(c, d + 1) }
        }
        if let main = attr(ax, kAXMainWindowAttribute) { walk(main as! AXUIElement, 0) }
        return found.sorted { $0.2 < $1.2 }.map { ($0.0, $0.1) }
    }

    /// G(n+1) pressed: the n-th page; answers what happened, for the app's line
    static func open(_ n: Int) -> String {
        let bar = pageBar()
        guard n < bar.count else { return "G\(n + 1): Resolve shows only \(bar.count) pages" }
        AXUIElementPerformAction(bar[n].el, kAXPressAction as CFString)
        return "G\(n + 1) → Resolve \(bar[n].name.uppercased()) page"
    }
}
