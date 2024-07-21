modimport("scripts/keybind_magic")

local TheInput = GLOBAL.TheInput
local KnownModIndex = GLOBAL.KnownModIndex

-- We have now defined keybinds in modinfo.lua
-- Reify them by assigning a callback to each

local modactualname = GLOBAL.KnownModIndex:GetModActualName(modinfo.name)
local key_handlers = {}

KEYBIND_MAGIC.on_keybinds_changed = function(changed_keybinds)
  -- Update mod config
  -- We're assuming that our keybind is never changed when the user has Mod Configuration screen open.
  -- This is the case for vanilla, but you can never be sure what crazy ideas some mod authors might have.
  -- Documenting this caveat here just in case.
  local config = KnownModIndex:LoadModConfigurationOptions(modactualname, true)
  for _, ck in ipairs(changed_keybinds) do
    local name = ck.name
    local new_key = ck.new_key

    -- Update key handler
    TheInput.onkeydown:RemoveHandler(key_handlers[name])
    if new_key ~= 0 then
      key_handlers[name] = TheInput:AddKeyDownHandler(new_key, handler)
    else
      key_handlers[name] = nil
    end

    -- Update value in the config
    config[modinfo.keybind_name2idx[name]].saved = KEYBIND_MAGIC.StringifyKeycode(new_key)
  end
  KnownModIndex:SaveConfigurationOptions(function() end, modactualname, config, true)
end

local function AddKeybind(name, handler)
  local conf_opt = modinfo.configuration_options[modinfo.keybind_name2idx[name]]
  local curr_keycode = KEYBIND_MAGIC.ParseKeyString(GetModConfigData(name))
  local def_keycode = KEYBIND_MAGIC.ParseKeyString(conf_opt.default)

  -- Add the initial key handler
  if new_key ~= 0 then
    key_handlers[name] = TheInput:AddKeyDownHandler(curr_keycode, handler)
  end

  KEYBIND_MAGIC.Add(conf_opt.label, def_keycode, curr_keycode)
end

AddKeybind("my_alice", function() print("Alice here!") end)
AddKeybind("my_bob", function() print("Bob here!") end)
AddKeybind("my_carol", function() print("Carol here!") end)
