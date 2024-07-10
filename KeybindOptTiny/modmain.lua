modimport("scripts/keybind_magic")

-- ChooseTranslationTable() provided in modindex.lua
-- Not available outside of modinfo.lua but we still need it
local function T(tbl)
  local locale = GLOBAL.LOC.GetLocaleCode()
  return tbl[locale] or tbl[1]
end

local keycode2key = { [0] = "KEY_DISABLED" }
local rawget = GLOBAL.rawget
for _, key_option in pairs(modinfo.keys) do
  local varname = key_option.data
  if varname ~= "KEY_DISABLED" then
    keycode2key[rawget(GLOBAL, varname)] = varname
  end
end
local function StringifyKeycode(keycode)
  return keycode2key[keycode]
end
local function ParseKeyString(key)
  return key == "KEY_DISABLED" and 0 or rawget(GLOBAL, key)
end

local key_handlers = {}

-- We have now defined keybinds in modinfo.lua
-- Reify them by assigning a callback to each

local modactualname = GLOBAL.KnownModIndex:GetModActualName(modinfo.name)

local function AddKeybind(id, handler)
  local kbd = modinfo.keybinds[id]
  local curr_keycode = ParseKeyString(GetModConfigData(id))
  local def_keycode = ParseKeyString(kbd._default_key)

  -- Add the initial key handler
  if new_key ~= 0 then
    key_handlers[id] = GLOBAL.TheInput:AddKeyDownHandler(curr_keycode, handler)
  end

  KeybindHandler:Add(T(kbd), def_keycode, curr_keycode, function(new_key)
    -- Update key handler
    GLOBAL.TheInput.onkeydown:RemoveHandler(key_handlers[id])
    if new_key ~= 0 then
      key_handlers[id] = GLOBAL.TheInput:AddKeyDownHandler(new_key, handler)
    else
      key_handlers[id] = nil
    end

    -- Update mod config
    local config = GLOBAL.KnownModIndex:LoadModConfigurationOptions(modactualname, true)
    config[kbd._config_idx].saved = StringifyKeycode(new_key)
		GLOBAL.KnownModIndex:SaveConfigurationOptions(function() end, modactualname, config, true)
  end)
end

AddKeybind("my_alice", function() print("Alice here!") end)
AddKeybind("my_bob", function() print("Bob here!") end)
AddKeybind("my_carol", function() print("Carol here!") end)
