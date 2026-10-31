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
        // v24 (Marko: "it does select those things ... but it doesn't actually switch to them"): AXPress only lights the
        // button in Resolve's Qt page bar; Resolve's own resolve.OpenPage switches, through the DaVinci Resolve Actions router
        let page = bar[n].name.lowercased()
        // v25 (Marko: "when I press the button, it needs to light up in the user interface of the E16 for DaVinci Resolve"):
        // every press told to E16 for DaVinci Resolve, which lights G(n+1) in its window
        DistributedNotificationCenter.default().postNotificationName(Notification.Name("community.auroville.g815.gkey"),
            object: nil, userInfo: ["key": n + 1, "page": bar[n].name], deliverImmediately: true)
        if openPage(page) { return "G\(n + 1) → Resolve \(bar[n].name.uppercased()) page" }
        AXUIElementPerformAction(bar[n].el, kAXPressAction as CFString)          // the router is not running: the old way
        return "G\(n + 1) → \(bar[n].name.uppercased()) (router off: only lit)"
    }

    /// the current page's position in the page bar (resolve.GetCurrentPage through the router), nil when Resolve does not answer
    static func currentIndex() -> Int? {
        var req = URLRequest(url: URL(string: "http://127.0.0.1:8940/run")!)
        req.httpMethod = "POST"; req.timeoutInterval = 2
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["who": "g815", "code": "result = resolve.GetCurrentPage()", "timeout": 2])
        var cur: String?
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { d, _, _ in
            cur = (d.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })?["result"] as? String
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 3)
        guard let c = cur else { return nil }
        return pageBar().firstIndex { $0.name.lowercased() == c }
    }

    /// resolve.OpenPage(page) through the router (POST 127.0.0.1:8940/run, as E16 for DaVinci Resolve does); true when switched
    static func openPage(_ page: String) -> Bool {
        var req = URLRequest(url: URL(string: "http://127.0.0.1:8940/run")!)
        req.httpMethod = "POST"; req.timeoutInterval = 3
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["who": "g815", "code": "result = resolve.OpenPage('\(page)')", "timeout": 3])
        var ok = false
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: req) { d, _, _ in
            if let d, let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any] { ok = (j["ok"] as? Bool ?? false) && (j["result"] as? Bool ?? false) }
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 4)
        return ok
    }
}
