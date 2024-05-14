name = "Beefalo keybind"
author = "Mingrain"
description = "快捷上下牛\nQuick up and down Beefalo"
version = "0.5"
api_version = 10
dst_compatible = true;
icon_atlas = "modicon.xml"
icon = "modicon.tex"
client_only_mod = true
all_clients_require_mod = false
server_only_mod = false
local keys = {
	"None",
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"LSHIFT","LALT","LCTRL","TAB","BACKSPACE","PERIOD","SLASH","TILDE","Mouse Button 4","Mouse Button 5"
}
configuration_options =
{
  {
    name = "key",
    label = "上下牛",
    hover = "快捷上下牛",
    options =
    {
     --不写
    },
    default = "R",
  },
  {
    name = "feed",
    label = "喂牛",
    hover = "选择最靠左的食物(Choos the leftmost)",
    options =
    {
     --不写
    },
    default = "Mouse Button 4",
  },
}
local function filltable(tbl)
	for i=1, #keys do
		tbl[i] = {description = keys[i], data = keys[i]}
	end
end
filltable(configuration_options[1].options)
filltable(configuration_options[2].options)