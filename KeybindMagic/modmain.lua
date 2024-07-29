modimport("keybind_magic")

local TheInput = GLOBAL.TheInput

-- This is a demo of how to work with keybind_magic.lua to have key-down handlers for all the keybinds.
-- Of course, you're free to do anything with the keybinds' bound keys. All keybind_magic.lua does is add an interface
-- for the players for rebind them.

-- The keybinds themselves are defined in modinfo.lua

-- Map from keybind name to a callback to be called when the keybind is pressed
local keybind_callbacks = {}
keybind_callbacks.my_alice = function() print("Alice here!") end
keybind_callbacks.my_bob = function() print("Bob here!") end
keybind_callbacks.my_carol = function() print("Carol here!") end

local registered_key_handlers = {}

-- Add the initial key handler
for name, cb in pairs(keybind_callbacks) do
  local key = KEYBIND_MAGIC.ParseKeyString(GetModConfigData(name))
  if key ~= 0 then
    registered_key_handlers[name] = TheInput:AddKeyDownHandler(key, cb)
  end
end

KEYBIND_MAGIC.on_keybind_changed = function(name, new_key)
  -- Update key handler to the newly bound key
  TheInput.onkeydown:RemoveHandler(registered_key_handlers[name])
  if new_key ~= 0 then
    registered_key_handlers[name] = TheInput:AddKeyDownHandler(new_key, keybind_callbacks[name])
  else
    registered_key_handlers[name] = nil
  end
end
