-- Load mod with global environment
mod = GLOBAL.kleiloadlua(MODROOT.."scripts/logic.lua")
print(mod)
GLOBAL.setfenv(mod, GLOBAL)
mod()

local beefaloKey = GetModConfigData("key")
if beefaloKey ~= "None" and beefaloKey ~= "Mouse Button 4" and beefaloKey ~= "Mouse Button 5" then
  local keybind = GLOBAL["KEY_"..beefaloKey]
  GLOBAL.TheInput:AddKeyDownHandler(keybind, function()
    if not GLOBAL.BeefaloKeybindsFuncs.IsInGameplay() then return end
    GLOBAL.BeefaloKeybindsFuncs.MountOrDis()
  end)
else
  local mouse = nil
  if beefaloKey == "Mouse Button 4" then
    mouse = 1005
  else
    mouse = 1006
  end
  GLOBAL.TheInput:AddMouseButtonHandler(function (button, down, x, y)
    if not GLOBAL.BeefaloKeybindsFuncs.IsInGameplay() then return end
    if button == mouse and down then
      GLOBAL.BeefaloKeybindsFuncs.MountOrDis()
    end
  end)
end

local feedKey = GetModConfigData("feed")
if feedKey ~= "None" and feedKey ~= "Mouse Button 4" and feedKey ~= "Mouse Button 5" then
  local keybind2 = GLOBAL["KEY_"..feedKey]
  GLOBAL.TheInput:AddKeyDownHandler(keybind2, function()
    if not GLOBAL.BeefaloKeybindsFuncs.IsInGameplay() then return end
    GLOBAL.BeefaloKeybindsFuncs.Feed()
  end)
else
  local mouse2 = nil
  if feedKey == "Mouse Button 4" then
    mouse2 = 1005
  else
    mouse2 = 1006
  end
  GLOBAL.TheInput:AddMouseButtonHandler(function(button, down, x, y)
    if not GLOBAL.BeefaloKeybindsFuncs.IsInGameplay() then return end
    if button == mouse2 and down then
      GLOBAL.BeefaloKeybindsFuncs.Feed()
    end
  end)
end
