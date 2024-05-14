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

local function InstallMouseKeybind(mouse_keycode, callback)
  GLOBAL.TheInput:AddMouseButtonHandler(function (button, down, x, y)
    if button == mouse_keycode and down then
      callback(button, down, x, y)
    end
  end)
end

local function InstallKeybind(config_key, callback)
  if config_key == "None" then return end

  if config_key == "Mouse Button 4" then
    return InstallMouseKeybind(1005, callback)
  elseif config_key == "Mouse Button 5" then
    return InstallMouseKeybind(1006, callback)
  end

  local keycode = GLOBAL["KEY_"..config_key]
  GLOBAL.TheInput:AddKeyDownHandler(keycode, callback)
end

InstallKeybind(
  GetModConfigData("key"),
  function()
    if not IsInGameplay() then return end
    MountOrDis()
  end)

InstallKeybind(
  GetModConfigData("feed"),
  function()
    if not IsInGameplay() then return end
    Feed()
  end)
