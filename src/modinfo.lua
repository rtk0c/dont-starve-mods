name = "Client Tweaks"
id = "rtk0c.DST_ClientTweaks" --unofficial field
author = "rtk0c"
description = "Various client tweaks"
version = "1.0"

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

api_version = 10

all_clients_require_mod = false
server_only_mod = false
client_only_mod = true



-------- Non-user-facing configuration options --------
-- These needs a reset (running modmain.lua again) to take effect

-- Expose development utilities
opt_dev_mode = true
-- If true, wraps game-facing callbacks in an error handler that merely logs the error without crashing
-- Disable this in production environment, or want to test mod in "real world conditions"
opt_safe_mode = true



local keys = {
  "None",
-- Alphanumeric keys
  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
  "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
  "MINUS", "EQUALS", "SPACE", "ENTER",
  "TAB", "BACKSPACE", "PERIOD", "COMMA", "SLASH", "BACKSLASH", "SEMICOLON", "LEFTBRACKET", "RIGHTBRACKET", "TILDE",
  -- These keys tend to have OS-level functionality bound to them, let's not
  --[["ESCAPE", "PAUSE", "PRINT", "CAPSLOCK", "SCROLLOCK",]]
  "HOME", "INSERT", "DELETE", "END",
  "PAGEUP", "PAGEDOWN",
  "UP", "DOWN", "RIGHT", "LEFT",
-- Functional row
  "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
-- Modifier keys
  "LSHIFT", "LCTRL", "LALT", "LSUPER", "RSHIFT", "RCTRL", "RALT", "RSUPER",
-- Numpad keys
  "KP_0", "KP_1", "KP_2", "KP_3", "KP_4", "KP_5", "KP_6", "KP_7", "KP_8", "KP_9",
  "KP_PERIOD", "KP_DIVIDE", "KP_MULTIPLY", "KP_MINUS", "KP_PLUS", "KP_ENTER", "KP_EQUALS",
-- Mouse buttons
  "Mouse Button 4", "Mouse Button 5"
}

local hotkey_options = {}
-- We cannot use ipairs because DST's mod loader doesn't provide access to global environment
-- for _, key in ipairs(keys) do
for i = 1, #keys do
  -- Similarly, no table.insert either
  -- table.insert(hotkey_options, {description = key, data = key})
  hotkey_options[#hotkey_options + 1] = {description = keys[i], data = keys[i]}
end

configuration_options = {
  {
    name = "key",
    label = "Mount/Dismount Beefalo",
    hover = "Hotkey for mounting and dismounting the closest beefalo.",
    options = hotkey_options,
    default = "R",
  },
  {
    name = "feed",
    label = "Feed Beefalo",
    hover = "Feed beefalo with the leftmost food item in inventory.",
    options = hotkey_options,
    default = "Mouse Button 4",
  },
}
