modimport("scripts/keybind")

local function MyKeybindHandler()
  print("here")
end

-- Load the default option, somehow
-- Maybe from configuration_options? maybe your own config storage system?
local my_keybind_eh = GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_B, MyKeybindHandler)

KeybindHandler:Add("My keybind", GLOBAL.KEY_B,
  function(new_key)
    local g_TI = GLOBAL.TheInput
    g_TI.onkeydown:RemoveHandler(my_keybind_eh)
    if new_key ~= 0 then
      my_keybind_eh = g_TI:AddKeyDownHandler(new_key, MyKeybindHandler)
    else
      my_keybind_eh = nil
    end
  end)
