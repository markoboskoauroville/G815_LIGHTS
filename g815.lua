-- g815.lua: G815 LIGHTS — every key of the Logitech G815 its own still colour and its own brightness.
--
-- Marko, 2.10.2026: "I need only static colors and each button individual colors. That's all. No effect,
-- nothing. Just a few memories of my settings." The app paints the keyboard from the active MEMORY at
-- every start of the star (so at every login), after every wake and every replug; the page at
-- 127.0.0.1:8859 edits it live. Three banks, M1 M2 M3, are the keyboard's own: choosing one on the page
-- switches the keyboard, pressing one on the keyboard switches the page. Every change is kept on the Mac
-- and, four seconds later, written into that bank of the keyboard — which can hold only one still colour
-- per zone, so the power-on is still, never a light show, and the app then paints the keys one by one
-- (LESSONS.md, "Why the per-key colours cannot live in the keyboard").
--
-- The wire is build/g815 (Swift, src/), held open as `g815 serve`: one line in, one JSON line out.
-- Settings: ~/.g815/settings.json. One global, G815, so the star's switch and `hs -c` reach it.
local M = {}

local HERE = debug.getinfo(1, "S").source:match("^@(.*/)")
local HOME = os.getenv("HOME")
local PORTS = dofile(HOME .. "/.local/lib/mantra/ports.lua")
local BIN = HERE .. "build/g815"
local DIR = HOME .. "/.g815"
local FILE = DIR .. "/settings.json"
local WANT_PORT = 8859
local PORT = WANT_PORT
local VERSION = 1

local LAYOUT = hs.json.read(HERE .. "layout.json")
local IDS = {}
for _, k in ipairs(LAYOUT.keys) do IDS[#IDS + 1] = k.id end

local conf, server, helper, poll, wake, bankTimer = nil, nil, nil, nil, nil, nil
local bankChosenAt = 0      -- a status asked before this moment may still name the old bank: ignored
-- ONE LINE AT A TIME. Two setInput calls close together lost a line (MEASURED 2.10.2026: the bank-M2
-- write never reached the helper, and every reply after it was handed to the wrong caller). So the next
-- line is written only when the last one has answered, and a line unanswered for 5 s ends the helper.
local queue, waiting, outbuf, deadline = {}, nil, "", nil
local live = { connected = false, brightness = nil, profile = nil, serial = "", error = "", said = "", banks = {} }

-- ---------------------------------------------------------------- settings
local function fresh(name)
    return { name = name, base = { c = "ffffff", b = 100 }, keys = {} }
end

-- THREE BANKS, the keyboard's own M1 M2 M3 (Marko, 2.10.2026: "I press the memory button and adjust my
-- keyboard settings ... and it stays under that memory as well as my computer as well inside the keyboard").
-- Bank i on the Mac holds every key; bank i in the keyboard holds what its memory can: one still colour
-- for the keys, one for the logo.
local BANKS = 3

local function save()
    hs.fs.mkdir(DIR)
    hs.json.write(conf, FILE, true, true)
end

local function load()
    local ok, t = pcall(hs.json.read, FILE)
    conf = (ok and type(t) == "table") and t or {}
    conf.memories = conf.memories or {}
    for i = 1, BANKS do
        conf.memories[i] = conf.memories[i] or fresh("M" .. i)
        conf.memories[i].name = "M" .. i
    end
    for i = #conf.memories, BANKS + 1, -1 do table.remove(conf.memories, i) end
    conf.active = conf.active or 1
    if not conf.memories[conf.active] then conf.active = 1 end
    conf.presets = conf.presets or {
        { name = "WHITE", c = "ffffff", b = 100 }, { name = "WARM", c = "ff8a2a", b = 100 },
        { name = "DIM", c = "ffffff", b = 25 }, { name = "OFF", c = "000000", b = 0 },
    }
end

local function memory() return conf.memories[conf.active] end

local function keyOf(id)
    local m = memory()
    return m.keys[id] or m.base
end

-- the colour that goes on the wire: the key's colour times its own brightness
local function sent(k)
    local c, b = tonumber(k.c, 16) or 0, math.max(0, math.min(100, tonumber(k.b) or 100)) / 100
    local function ch(v) return math.floor(v * b + 0.5) end
    return string.format("%02x%02x%02x", ch(c >> 16 & 0xFF), ch(c >> 8 & 0xFF), ch(c & 0xFF))
end

-- ---------------------------------------------------------------- the helper (build/g815 serve)
local pump
local function onLine(line)
    local ok, r = pcall(hs.json.decode, line)
    if not ok or type(r) ~= "table" then return end
    if r.connected ~= nil then live.connected = r.connected end
    if r.ok then live.error = "" else live.error = r.error or "?" end
    if r.brightness then live.brightness = r.brightness end
    if r.profile then live.profile = r.profile end
    if r.serial then live.serial = r.serial end
    local w = waiting
    waiting = nil
    if deadline then deadline:stop(); deadline = nil end
    if w then pcall(w.cb, r) end
    pump()
end

local function helperStart()
    if helper and helper:isRunning() then return true end
    outbuf = ""
    helper = hs.task.new(BIN, function()
        -- it ended: whoever waited gets an error, the next line starts it again
        local w = waiting
        waiting, helper = nil, nil
        if w then pcall(w.cb, { ok = false, error = "the helper ended" }) end
        hs.timer.doAfter(0.2, function() pump() end)
    end, function(_, out)
        outbuf = outbuf .. (out or "")
        while true do
            local line, rest = outbuf:match("^([^\n]*)\n(.*)$")
            if not line then break end
            outbuf = rest
            onLine(line)
        end
        return true
    end, { "serve" })
    return helper:start() ~= nil
end

pump = function()
    if waiting or #queue == 0 then return end
    if not helperStart() then return end
    waiting = table.remove(queue, 1)
    if waiting.build then waiting.line = waiting.build() end   -- a paint is written as late as possible
    helper:setInput(waiting.line .. "\n")
    deadline = hs.timer.doAfter(5, function()
        deadline = nil
        print("g815: no answer to '" .. waiting.line:sub(1, 30) .. "', helper restarted")
        if helper then helper:terminate() end
    end)
end

local function send(line, cb)
    queue[#queue + 1] = { line = line, cb = cb or function() end }
    pump()
end

-- ---------------------------------------------------------------- painting
-- A PAINT WAITING IN LINE TAKES THE NEXT ONE IN: the keys are gathered in `dirty` and their colours are
-- read when the line is written, so a drag that sends twenty paints costs one or two, never a backlog.
local dirty, paintQueued = {}, nil
local function paint(ids, cb)
    for _, id in ipairs(ids) do dirty[id] = true end
    if paintQueued then
        if cb then local was = paintQueued.cb; paintQueued.cb = function(r) was(r); cb(r) end end
        return
    end
    paintQueued = { line = "paint", cb = cb or function() end, build = function()
        local parts = {}
        for id in pairs(dirty) do parts[#parts + 1] = id .. ":" .. sent(keyOf(id)) end
        dirty, paintQueued = {}, nil
        return "paint " .. table.concat(parts, " ")
    end }
    queue[#queue + 1] = paintQueued
    pump()
end

local function paintAll(why)
    local name = memory().name
    paint(IDS, function(r)
        if r.ok then print(string.format("g815: painted %s (%s)", name, why)) end
    end)
end

-- the colour most keys show, for the keyboard's own memory (one colour per zone is all it holds)
local function dominant(m)
    m = m or memory()
    local count, best, n = {}, "ffffff", 0
    for _, id in ipairs(IDS) do
        if id ~= "d2" then
            local s = sent(m.keys[id] or m.base)
            count[s] = (count[s] or 0) + 1
            if count[s] > n then best, n = s, count[s] end
        end
    end
    return best
end

-- ---------------------------------------------------------------- the banks
-- the keyboard's bank i gets bank i's still colours. The writer reads the sector first and does not
-- write when nothing changed, so a bank is only flashed when its colours really moved.
local function writeBank(i)
    local m = conf.memories[i]
    local logo = m.keys["d2"] or m.base
    live.banks["M" .. i] = "saving"
    send(string.format("onboard %d %s %s", i, dominant(m), sent(logo)), function(r)
        live.banks["M" .. i] = r.ok and ("saved " .. os.date("%H:%M")) or ("not saved: " .. tostring(r.error))
        -- writing a bank can make the keyboard reload it, which drops the per-key frame: paint again
        if r.ok and i == conf.active then paintAll("after saving bank " .. i) end
    end)
end

-- four seconds after the last change, the active bank goes into the keyboard
local function bankLater()
    if bankTimer then bankTimer:stop() end
    local i = conf.active
    bankTimer = hs.timer.doAfter(4, function() bankTimer = nil; writeBank(i) end)
end

-- a bank chosen on the page: the keyboard switches to it too, then the keys are painted
local function setBank(i)
    if bankTimer then bankTimer:fire() end            -- the bank being left is saved first
    conf.active = i
    bankChosenAt = hs.timer.secondsSinceEpoch()
    save()
    live.profile = i
    send("profile " .. i)
    paintAll("bank M" .. i)
end

-- ---------------------------------------------------------------- state and verbs
local function state()
    local m = memory()
    local names = {}
    for i, mm in ipairs(conf.memories) do names[i] = mm.name end
    local keys = {}
    for _, id in ipairs(IDS) do local k = keyOf(id); keys[id] = { c = k.c, b = k.b } end
    return {
        version = VERSION, memories = names, active = conf.active, keys = keys,
        presets = conf.presets, live = live,
    }
end

local function hexok(c) return type(c) == "string" and c:match("^%x%x%x%x%x%x$") ~= nil end

local function do_(v)
    local a = v.a
    if a == "paint" and type(v.ids) == "table" then
        local m, done = memory(), {}
        for _, id in ipairs(v.ids) do
            if type(id) == "string" and id:match("^%x%x$") then
                local k = { c = m.keys[id] and m.keys[id].c or m.base.c, b = m.keys[id] and m.keys[id].b or m.base.b }
                if hexok(v.c) then k.c = v.c:lower() end
                if tonumber(v.b) then k.b = math.max(0, math.min(100, math.floor(tonumber(v.b)))) end
                m.keys[id] = k
                done[#done + 1] = id
            end
        end
        save()
        paint(done)
        bankLater()
    elseif a == "memory" and conf.memories[tonumber(v.i) or 0] then
        setBank(tonumber(v.i))
    elseif a == "presetSave" and hexok(v.c) then
        local name = (type(v.name) == "string" and #v.name > 0) and v.name:upper():sub(1, 16) or ("#" .. v.c:upper())
        conf.presets[#conf.presets + 1] = { name = name, c = v.c:lower(), b = math.floor(tonumber(v.b) or 100) }
        save()
    elseif a == "presetDelete" and conf.presets[tonumber(v.i) or 0] then
        table.remove(conf.presets, tonumber(v.i))
        save()
    elseif a == "bright" and tonumber(v.v) then
        send("bright " .. math.floor(tonumber(v.v)))
    elseif a == "repaint" then
        paintAll("asked")
    elseif a == "saveAll" then
        for i = 1, BANKS do writeBank(i) end
    end
    return state()
end
M.do_ = do_

-- ---------------------------------------------------------------- the server
local function handle(method, path, _, body)
    local JSON = { ["Content-Type"] = "application/json" }
    if path == "/health" then return "ok", 200, { ["Content-Type"] = "text/plain" } end
    if path == "/state" then return hs.json.encode(state()), 200, JSON end
    if path == "/layout.json" then return hs.json.encode(LAYOUT), 200, JSON end
    if method == "POST" and path == "/do" then
        local ok, v = pcall(hs.json.decode, body or "{}")
        if not ok or type(v) ~= "table" then return hs.json.encode(state()), 200, JSON end
        local ok2, s = pcall(do_, v)
        if not ok2 then print("g815: /do: " .. tostring(s)); s = state() end
        return hs.json.encode(s), 200, JSON
    end
    local f = io.open(HERE .. "page.html", "r")
    local html = f and f:read("a") or "page.html missing"
    if f then f:close() end
    return html, 200, { ["Content-Type"] = "text/html; charset=utf-8" }
end

-- ---------------------------------------------------------------- the switch
function M.running() return server ~= nil end
function M.url() return "http://127.0.0.1:" .. PORT end
function M.state() return state() end
function M.live() return live end

function M.start()
    load()
    if not hs.fs.attributes(BIN) then return false, "build/g815 is missing: run build.sh" end
    PORT = PORTS.claim("g815", WANT_PORT)
    local srv = hs.httpserver.new(false, false)
    srv:setInterface("localhost"):setPort(PORT):setCallback(handle)
    if not pcall(function() srv:start() end) then return false, "the page's port could not be opened" end
    server = srv
    paintAll("start")
    -- every second: is it there, and which bank is it on? A keyboard that comes back (replug, power) is
    -- painted again; an M key pressed on the keyboard itself switches the page's bank as well.
    send("profile " .. conf.active)
    poll = hs.timer.doEvery(1, function()
        if waiting or #queue > 0 then return end        -- the helper is busy: do not queue up behind it
        local was, asked = live.connected, hs.timer.secondsSinceEpoch()
        send("status", function(r)
            if not r.ok or asked < bankChosenAt then return end
            if r.profile and r.profile ~= conf.active and conf.memories[r.profile] and not bankTimer then
                conf.active = r.profile
                save()
                paintAll("M" .. r.profile .. " pressed on the keyboard")
            elseif not was then
                paintAll("keyboard came back")
            end
        end)
    end)
    -- after sleep the keyboard may have played its own memory: paint again
    wake = hs.caffeinate.watcher.new(function(e)
        if e == hs.caffeinate.watcher.systemDidWake or e == hs.caffeinate.watcher.screensDidUnlock then
            hs.timer.doAfter(1.5, function() if server then paintAll("wake") end end)
        end
    end):start()
    return true, "G815 Lights is up on " .. M.url()
end

function M.stop()
    if bankTimer then bankTimer:fire(); bankTimer = nil end
    if poll then poll:stop(); poll = nil end
    if wake then wake:stop(); wake = nil end
    if server then pcall(function() server:stop() end); server = nil end
    if helper then pcall(function() helper:terminate() end); helper = nil end
    queue, waiting, dirty, paintQueued = {}, nil, {}, nil
    if deadline then deadline:stop(); deadline = nil end
    return true, "G815 Lights stopped (the keys keep their colours)"
end

function M.menu()
    if not M.running() then return nil end
    local items = {
        { title = "Open the page", fn = function() hs.execute("open -a 'Google Chrome' " .. M.url()) end },
        { title = "Paint the keyboard again", fn = function() paintAll("menu") end },
        { title = "-" },
    }
    for i, m in ipairs(conf.memories) do
        items[#items + 1] = { title = m.name, checked = i == conf.active, fn = function() do_({ a = "memory", i = i }) end }
    end
    items[#items + 1] = { title = "-" }
    items[#items + 1] = { title = live.connected and ("G815 connected, brightness " .. tostring(live.brightness)) or "G815 not connected", disabled = true }
    return items
end

G815 = M
return M
