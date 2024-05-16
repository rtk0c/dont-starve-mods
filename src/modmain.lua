modimport("scripts/log")
modimport("scripts/safe")
modimport("scripts/modfiles")

local function RunReloadableScripts()
  -- Load mod with global environment
  -- Let modfiles to write to the EXPORTS global variable to provide things to this mod environment  
  local old_global_exports = GLOBAL.EXPORTS
  -- `env` global variable contains a ref to the environment table itself, i.e. `env == GLOBAL.getfenv(1)`
  GLOBAL.EXPORTS = env
  for _, modfile in ipairs(modfiles_reloadable) do
    local path = MODROOT .. "scripts/" .. modfile
    local chunk = GLOBAL.kleiloadlua(path)
    if GLOBAL.type(chunk) == "function" then
      GLOBAL.setfenv(chunk, GLOBAL)
      chunk()
    else
      LogError("Failed to compile script at " .. path)
    end
  end
  GLOBAL.EXPORTS = old_global_exports
end

-- Declare global variable EXPORTS with value nil, otherwise no-op
-- Needed to convince strict.lua that yes, it is fine in this case to access an undeclared variable
GLOBAL.EXPORTS = GLOBAL.rawget(GLOBAL, "EXPORTS")
-- If errors occur here, just let it fail
RunReloadableScripts()



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
  SafeWrapper(function()
    if not IsInGameplay() then return end
    MountOrDis()
  end))

InstallKeybind(
  GetModConfigData("feed"),
  SafeWrapper(function()
    if not IsInGameplay() then return end
    Feed()
  end))



if modinfo.opt_dev_mode then
  GLOBAL.clienttweaks_hotreload = function()
    LogInfo("Reloading")

    -- FIXME this really isn't needed, since console commands are wrapped in pcall already
    local status, res = GLOBAL.pcall(RunReloadableScripts)
    if status then
      LogInfo("Reloading completed")
    else
      LogError("Reloading failed with error: " .. tostring(res))
    end
  end
end
