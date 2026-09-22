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
local move: any = win:Tab("Movement")
move:AddToggle("Hop", cfg.Hop, function(v: boolean) cfg.Hop = v end)
move:AddSlider("Speed", 16, 100, cfg.Speed, function(v: number) cfg.Speed = v end)
move:AddKeybind("Use", cfg.Key, function(k: Enum.KeyCode) cfg.Key = k end)
local misc: any = win:Tab("Misc")
misc:AddButton("Ping", function() print("pong") end)
print("[demo] ok")
