-- loader.luau: loadstring(game:HttpGet("https://raw.githubusercontent.com/scramblepaws/omni-lib/main/loader.luau"))()
getgenv().Repo = getgenv().Repo or { Base = "https://raw.githubusercontent.com/scramblepaws/omni-lib/main" }
local Base: string = getgenv().Repo.Base

local ok, err = pcall(function()
	getgenv().Menu = loadstring(game:HttpGet(Base .. "/ui-lib.luau"))()
end)
if not ok then warn("[loader] lib: " .. tostring(err)) return end

-- ponytail: hosted demo wins, inline fallback so the one-liner always shows something
local okDemo = pcall(function()
	loadstring(game:HttpGet(Base .. "/demo.luau"))()
end)
if not okDemo then
	local win: any = getgenv().Menu.Window("omni")
	local misc: any = win:Tab("Misc")
	misc:AddButton("Ping", function() print("pong") end)
end
print("[loader] ok")
