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

icon_atlas = "modicon.xml"
icon = "modicon.tex"



-------- Non-user-facing configuration options --------
-- These needs a reset (running modmain.lua again) to take effect

-- Expose development utilities
opt_dev_mode = true



local keys = {
  "None",
  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
  "LSHIFT", "LALT", "LCTRL", "TAB", "BACKSPACE", "PERIOD", "SLASH", "TILDE",
  "Mouse Button 4", "Mouse Button 5"
}

configuration_options =
{
  {
    name = "key",
    label = "上下牛",
    hover = "快捷上下牛",
    options = {
    },
    default = "R",
  },
  {
    name = "feed",
    label = "喂牛",
    hover = "选择最靠左的食物(Choos the leftmost)",
    options = {
    },
    default = "Mouse Button 4",
  },
}

local function filltable(tbl)
  for i = 1, #keys do
    tbl[i] = {description = keys[i], data = keys[i]}
  end
end
filltable(configuration_options[1].options)
filltable(configuration_options[2].options)
