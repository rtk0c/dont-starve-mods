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
  'Disabled', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  'Disabled', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'Disabled', 'Tab', 'CapsLock', 'LShift', 'LCtrl', 'LAlt', 'Space', 'RAlt', 'RCtrl', 'Period', 'Slash', 'RShift',
  'Disabled', 'Minus', 'Equals', 'Backspace', 'LeftBracket', 'RightBracket', 'Backslash', 'Semicolon', 'Enter',
  'Disabled', 'Up', 'Down', 'Left', 'Right', 'Insert', 'Delete', 'Home', 'End', 'PageUp', 'PageDown', -- navigation
  'Disabled', 'Num 0', 'Num 1', 'Num 2', 'Num 3', 'Num 4', 'Num 5', 'Num 6', 'Num 7', 'Num 8', 'Num 9', -- numberic keypad
  'Num Period', 'Num Divide', 'Num Multiply', 'Num Minus', 'Num Plus', 'Disabled',
}
for i = 1, #keys do
  local k = keys[i]
  keys[i] = {
    description = k,
    data = 'KEY_' .. k:gsub('^Num ', 'KP_'):upper(),
  }
end

-- https://github.com/liolok/BossCalendarLite/blob/master/modinfo.lua#L181
local function Header(title)
  return { name = T(title), options = { { description = '', data = 0 } }, default = 0 }
end

configuration_options = {
  Header({"Basic options", zh="普通选项", zht="普通選項"}),
  {
    name = "basic_option_1",
    label = T({"Basic option 1", zh="普通选项1", zht="普通選項1"}),
    default = "foo",
    options = {
      { description="foo", data="foo" },
      { description="bar", data="bar" },
    },
  },
  Header({"Keybinds", zh="快捷键", zht="快捷鍵"}),
  {
    name = "my_alice",
    label = T({"Alice", zh="爱丽丝", zht="愛麗絲"}),
    hover = T({"Test hover text", zh="测试用详细描述", zht="測試用詳細描述"}),
    default = "KEY_F",
    -- A config option is considered a keybind if its `option` property is set to `modinfo.keys`
    options = keys,
  },
  {
    name = "my_bob",
    label = T({"Bob", zh="鲍勃", zht="鮑勃"}),
    hover = T({
      "Test longer longer longer longer longer longer longer longer longer longer hover text",
      zh="测试用超长长长长长长长长长长长长长长长长长详细描述",
      zht="測試用超長長長長長長長長長長長長長長長長長詳細描述",
    }),
    default = "KEY_G",
    options = keys,
  },
  {
    name = "my_carol",
    label = T({"Carol", zh="卡罗", zht="卡羅"}),
    default = "KEY_H",
    options = keys,
  },
  {
    name = "keybind_1",
    label = "Dummy keybind 1",
    default = "KEY_H",
    options = keys,
  },
  {
    name = "keybind_2",
    label = "Dummy keybind 2",
    default = "KEY_H",
    options = keys,
  },
  {
    name = "keybind_3",
    label = "Dummy keybind 3",
    default = "KEY_H",
    options = keys,
  },
  {
    name = "keybind_4",
    label = "Dummy keybind 4",
    default = "KEY_H",
    options = keys,
  },
  {
    name = "keybind_5",
    label = "Dummy keybind 5",
    default = "KEY_H",
    options = keys,
  },
  {
    name = "keybind_6",
    label = "Dummy keybind 6",
    default = "KEY_H",
    options = keys,
  },
}
