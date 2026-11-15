// lightclient.swift — `g815 show|frame|stop|status|shows|layout`: the command line over the app's light API
// (127.0.0.1:8877, app/LightShow.swift; the app must be running). v35, 15.11.2026.
//   g815 status | shows | layout | stop
//   g815 show <name|all> [seconds-per-show]
//   g815 frame <picture file> [stretch|contain|cover]     a PNG/JPEG laid over the whole keyboard
//   g815 frame color <rrggbb>                             every key one colour
//   g815 frame keys 26:ff0000 37:00ff00 ...               only these keys lit, the rest dark

import Foundation

func lightHTTP(_ method: String, _ path: String, body: Data? = nil, type: String = "application/json") -> String {
    var req = URLRequest(url: URL(string: "http://127.0.0.1:8877" + path)!)
    req.httpMethod = method; req.timeoutInterval = 10
    if let b = body { req.httpBody = b; req.setValue(type, forHTTPHeaderField: "Content-Type") }
    let sem = DispatchSemaphore(value: 0)
    var out = "{\"ok\":false,\"error\":\"G815 Lights is not running (nothing answers on 127.0.0.1:8877)\"}"
    URLSession.shared.dataTask(with: req) { d, _, _ in
        if let d { out = String(decoding: d, as: UTF8.self) }
        sem.signal()
    }.resume()
    sem.wait()
    return out
}

func lightCLI(_ args: [String]) -> Bool {
    guard let verb = args.first, ["show", "frame", "stop", "status", "shows", "layout"].contains(verb) else { return false }
    switch verb {
    case "status": print(lightHTTP("GET", "/status"))
    case "shows": print(lightHTTP("GET", "/shows"))
    case "layout": print(lightHTTP("GET", "/layout"))
    case "stop": print(lightHTTP("POST", "/stop"))
    case "show":
        guard args.count > 1 else { print("usage: g815 show <name|all> [seconds]"); exit(1) }
        print(lightHTTP("POST", "/show/\(args[1])" + (args.count > 2 ? "?seconds=\(args[2])" : "")))
    default:
        guard args.count > 1 else { print("usage: g815 frame <picture> [stretch|contain|cover] | color <rrggbb> | keys 26:ff0000 ..."); exit(1) }
        if args[1] == "color", args.count > 2 {
            print(lightHTTP("POST", "/frame", body: Data("{\"color\":\"\(args[2])\"}".utf8)))
        } else if args[1] == "keys" {
            var d: [String: String] = [:]
            for a in args.dropFirst(2) { let p = a.split(separator: ":"); if p.count == 2 { d[String(p[0])] = String(p[1]) } }
            let j = try? JSONSerialization.data(withJSONObject: ["keys": d])
            print(lightHTTP("POST", "/frame", body: j))
        } else {
            let path = NSString(string: args[1]).expandingTildeInPath
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { print("cannot read \(path)"); exit(1) }
            print(lightHTTP("POST", "/frame" + (args.count > 2 ? "?fit=\(args[2])" : ""), body: data, type: "image/png"))
        }
    }
    return true
}
