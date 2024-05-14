modimport("scripts/safe")
modimport("scripts/modfiles")

-- Load mod with global environment
-- Let modfiles to write to the EXPORTS global variable to provide things to this mod environment
local old_global_exports = GLOBAL.rawget(GLOBAL, "EXPORTS") -- Use rawget to not trigger an error if nobody else is using EXPORTS (it is undeclared)
GLOBAL.EXPORTS = env -- `env` global variable contains a ref to the env table itself, i.e. `env == GLOBAL.getfenv(1)`
for _, modfile in ipairs(modfiles_reloadable) do
  local chunk = GLOBAL.kleiloadlua(MODROOT.."scripts/"..modfile)
  GLOBAL.setfenv(chunk, GLOBAL)
  chunk()
end
GLOBAL.EXPORTS = old_global_exports

local beefaloKey = GetModConfigData("key")
if beefaloKey ~= "None" and beefaloKey ~= "Mouse Button 4" and beefaloKey ~= "Mouse Button 5" then
  local keybind = GLOBAL["KEY_"..beefaloKey]
  GLOBAL.TheInput:AddKeyDownHandler(keybind, function()
    if not IsInGameplay() then return end
    MountOrDis()
  end)
else
  local mouse = nil
  if beefaloKey == "Mouse Button 4" then
    mouse = 1005
  else
    mouse = 1006
  end
  GLOBAL.TheInput:AddMouseButtonHandler(function (button, down, x, y)
    if not IsInGameplay() then return end
    if button == mouse and down then
      MountOrDis()
    end
  end)
end

local feedKey = GetModConfigData("feed")
if feedKey ~= "None" and feedKey ~= "Mouse Button 4" and feedKey ~= "Mouse Button 5" then
  local keybind2 = GLOBAL["KEY_"..feedKey]
  GLOBAL.TheInput:AddKeyDownHandler(keybind2, function()
    if not IsInGameplay() then return end
    Feed()
  end)
else
  local mouse2 = nil
  if feedKey == "Mouse Button 4" then
    mouse2 = 1005
  else
    mouse2 = 1006
  end
  GLOBAL.TheInput:AddMouseButtonHandler(function(button, down, x, y)
    if not IsInGameplay() then return end
    if button == mouse2 and down then
      Feed()
    end
  end)
end
