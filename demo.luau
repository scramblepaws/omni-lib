-- demo.luau | runnable proof for omni lib (run ui-lib first, or via loader)
local Menu: any = getgenv().Menu
if not Menu and typeof(readfile) == "function" then
	local ok, src = pcall(readfile, "ui-lib.luau")
	if ok and typeof(src) == "string" then Menu = loadstring(src)() end
end
assert(Menu, "[demo] run ui-lib.luau first, then demo")

getgenv().Demo = getgenv().Demo or { Hop = true, Speed = 16.0, Key = Enum.KeyCode.E }
local cfg = getgenv().Demo

local win: any = Menu.Window("omni", Enum.KeyCode.RightShift)
local gen: any = win:Tab("General")
gen:AddToggle("Hop", cfg.Hop, function(v: boolean) cfg.Hop = v end)
gen:AddSlider("Speed", 16, 100, cfg.Speed, function(v: number) cfg.Speed = v end)
gen:AddKeybind("Use", cfg.Key, function(k: Enum.KeyCode) cfg.Key = k end)
gen:AddDropdown("Modes", { "Casual", "Ranked", "Deathmatch" }, { true, false, false }, function(s: { boolean }) print("modes", s[1], s[2], s[3]) end)
local set: any = win:Tab("Settings")
set:AddColor("Accent", Color3.fromRGB(178, 156, 255), function(c: Color3) print("accent", tostring(c)) end)
local misc: any = win:Tab("Other")
misc:AddButton("Ping", function() print("pong") end)
print("[demo] ok")
