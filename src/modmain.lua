modimport("scripts/log")
modimport("scripts/safe")
modimport("scripts/keybind")
modimport("scripts/modfiles")

local function RunReloadableScripts(safe)
  -- Load mod with global environment
  -- Let modfiles to write to the EXPORTS global variable to provide things to this mod environment  
  local old_global_exports = GLOBAL.EXPORTS
  -- `env` global variable contains a ref to the environment table itself, i.e. `env == GLOBAL.getfenv(1)`
  GLOBAL.EXPORTS = env
  for _, modfile in ipairs(modfiles_reloadable) do
    local path = MODROOT .. "scripts/" .. modfile
    local chunk = GLOBAL.kleiloadlua(path)
    if safe then
      -- Bleh, Lua doesn't have continue, so deep nesting in we go!
      ---- Safety Checks ----
      if GLOBAL.type(chunk) ~= "function" then
        LogError("Failed to compile script at " .. path)
      else
        GLOBAL.setfenv(chunk, GLOBAL)
        local status, res = GLOBAL.pcall(chunk)
        if status then
          -- No-op
        else
          LogError("Failed to load script with error: \n" .. tostring(res))
        end
      end
    else
      ---- No checks ----
      GLOBAL.setfenv(chunk, GLOBAL)
      chunk()
    end
  end
  GLOBAL.EXPORTS = old_global_exports
end

-- Declare global variable EXPORTS with value nil, otherwise no-op
-- Needed to convince strict.lua that yes, it is fine in this case to access an undeclared variable
GLOBAL.EXPORTS = GLOBAL.rawget(GLOBAL, "EXPORTS")
-- Even if safe mode is on in prod:
-- The mod scripts failed here, so it must be completely faulty, there is no reason to continue at all.
-- But in dev mode, we might start with faulty code, and wants to iterate on it until it works, and that is much more convenient with hotreloading than keep relaunching the game. As such, we allow faulty scripts to proceed in dev mode.
if modinfo.opt_dev_mode then
  RunReloadableScripts(true)

  GLOBAL.clienttweaks_hotreload = function()
    LogInfo("Reloading")
    -- Even though console command is already in pcall(), we still want safe mode for per-file error reporting
    RunReloadableScripts(true)
    LogInfo("Reload finished")
  end
else
  RunReloadableScripts()
end



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
