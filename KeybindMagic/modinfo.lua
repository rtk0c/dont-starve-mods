name = "KeybindMagic Demo Mod"
author = "rtk0c"
description = [[Demo mod for keybind_magic.lua
https://github.com/rtk0c/dont-starve-mods/tree/master/KeybindMagic]]
version = "1.0"

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

api_version = 10

all_clients_require_mod = false
server_only_mod = false
client_only_mod = true

-- Function picking the correct local string
local T = ChooseTranslationTable

-- Generate a list of all available keys
-- From https://github.com/liolok/RangeIndicator/blob/master/modinfo.lua
keys = { -- from STRINGS.UI.CONTROLSSCREEN.INPUTS[1] of strings.lua, need to match constants.lua too.
  'Disabled', 'Escape', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'Print', 'ScrolLock', 'Pause',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'Tab', 'CapsLock', 'LShift', 'LCtrl', 'LAlt', 'Space', 'RAlt', 'RCtrl', 'Period', 'Slash', 'RShift',
  'Minus', 'Equals', 'Backspace', 'LeftBracket', 'RightBracket', 'Backslash', 'Semicolon', 'Enter',
  'Up', 'Down', 'Left', 'Right', 'Insert', 'Delete', 'Home', 'End', 'PageUp', 'PageDown', -- navigation
  'Num 0', 'Num 1', 'Num 2', 'Num 3', 'Num 4', 'Num 5', 'Num 6', 'Num 7', 'Num 8', 'Num 9', -- numberic keypad
  'Num Period', 'Num Divide', 'Num Multiply', 'Num Minus', 'Num Plus', 'Disabled',
}
for i = 1, #keys do
  local k = keys[i]
  keys[i] = {
    description = k,
    data = 'KEY_' .. k:gsub('^Num ', 'KP_'):upper(),
  }
end

configuration_options = {}
-- Map from keybind name to index in configuration_options
-- To iterate all keybinds, do it like this: `for name, idx in pairs(modinfo.keybind_name2idx)`
keybind_name2idx = {} -- custom field

local declaring_keybinds = {
  -- For terseness in this demo, I put extra info into the translation table (first 3 entries here)
  -- In practice you should probably take them out
  { _name = "my_alice",   _default_key = "KEY_F",   "Alice", zh="爱丽丝", zht="愛麗絲" },
  { _name = "my_bob",     _default_key = "KEY_G",   "Bob",   zh="鲍勃",   zht="鮑勃" },
  { _name = "my_carol",   _default_key = "KEY_H",   "Carol", zh="卡罗",   zht="卡羅" },
}
-- Do 2 things:
-- 1. Generate config options
-- 2. Turn the array into a hashtable
--    We have to use an array in modinfo.lua, because pairs() isn't available, so iterating a hashtable is not possible
for i = 1, #declaring_keybinds do
  local dk = declaring_keybinds[i]
  configuration_options[#configuration_options + 1] = {
    name = dk._name,
    label = T(dk),
    default = dk._default_key,
    options = keys,
  }
  keybind_name2idx[dk._name] = #configuration_options
end
