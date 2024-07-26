modimport("scripts/keybind_magic")

local TheInput = GLOBAL.TheInput
local KnownModIndex = GLOBAL.KnownModIndex

-- We have now defined keybinds in modinfo.lua
-- Reify them by assigning a callback to each

local modactualname = GLOBAL.KnownModIndex:GetModActualName(modinfo.name)
local key_callbacks = {}
key_callbacks.my_alice = function() print("Alice here!") end
key_callbacks.my_bob = function() print("Bob here!") end
key_callbacks.my_carol = function() print("Carol here!") end

local key_handlers = {}

-- Add the initial key handler
for name, fn in pairs(key_handlers) do
  local key = KEYBIND_MAGIC.ParseKeyString(GetModConfigData(name))
  if key ~= 0 then
    key_handlers[name] = TheInput:AddKeyDownHandler(key, fn)
  end
end

KEYBIND_MAGIC.on_keybinds_changed = function(changed_keybinds)
  -- TODO 直接把这坨同步mod config的移到keybind_magic.lua里算了
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
