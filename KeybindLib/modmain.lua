local function RunFileInGlobal(path)
  local chunk = GLOBAL.kleiloadlua(MODROOT .. path)
  GLOBAL.setfenv(chunk, GLOBAL)
  chunk()
end
RunFileInGlobal("scripts/keybind.lua")
RunFileInGlobal("scripts/keybind_screen.lua")

AddGamePostInit(function() GLOBAL.KeybindLib:LoadKeybindMappings() end)

--[[
GLOBAL.TheInput:AddMouseButtonHandler(function(button, down, x, y))
  print("Mouse button: button="..button.." down="..tostring(down).." x="..x.." y="..y)
end
GLOBAL.TheInput:AddKeyHandler(function(key, down)
  print("Key: key="..key.." down="..tostring(down))
end)
--]]
