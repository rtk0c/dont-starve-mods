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

configuration_options = {
  {
    name = "my_alice",
    label = T({"Alice", zh="爱丽丝", zht="愛麗絲"}),
    default = "KEY_F",
    options = keys,
    -- Custom field, keybind_magic.lua reads this to identify keybinds out of all the configuration options
    is_keybind = true,
  },
  {
    name = "my_bob",
    label = T({"Bob", zh="鲍勃", zht="鮑勃"}),
    default = "KEY_G",
    options = keys,
    is_keybind = true,
  },
  {
    name = "my_carol",
    label = T({"Carol", zh="卡罗", zht="卡羅"}),
    default = "KEY_H",
    options = keys,
    is_keybind = true,
  },
}
