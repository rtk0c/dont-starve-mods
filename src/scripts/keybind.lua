kbd_list = {}

-------
-- @param kbd The keybind object.
-- @param kbd.id An unique identifier for this keybind.
-- @param kbd.name A human-readable (and preferrably localized) name for this keybind. For dispaly in UI.
-- @param kbd.callback Function to be called when the keybind is triggered.
function RegisterKeybind(kbd)
  kbd.input_mask = 0 -- Mask for unset keybind
  GLOBAL.table.insert(kbd_list, kbd)
end

RegisterKeybind({
  id = "test_kbd",
  name = "Test Keybind",
  callback = function() print("keybind pressed!") end,
})
