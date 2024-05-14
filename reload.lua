-------- INTERACTIVE USE --------
-- Runs everything in modfiles_reloadable.
-- This is NOT loaded as a part of the normal mod loading cycle at all.
-- This file is intended to be executed interactively with dofile() and etc.

-- Find our mod
local mod = nil
for _, cand in ipairs(ModManager.mods) do
  if cand.modinfo.id == "rtk0c.DST_ClientTweaks" then
    mod = cand
    break
  end
end
if mod == nil then
  return
end

-- The `mod` table is the environment of modmain.lua
-- Its key "modinfo" is the environment of modinfo.lua

local old_global_exports = rawget(_G, "EXPORTS")
EXPORTS = mod
for _, modfile in ipairs(mod.modfiles_reloadable) do
  local chunk = kleiloadlua(mod.MODROOT.."scripts/"..modfile)
  setfenv(chunk, _G)
  chunk()
end
EXPORTS = old_global_exports
