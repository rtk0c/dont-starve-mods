name = "[API] KeybindLib"
author = "rtk0c"
description = [[Library for handling keybinds, in a sane manner. For both users and developers.

See https://github.com/rtk0c/dont-starve-mods/tree/master/KeybindLib for documentation.
This mod is published at https://fontawesome.com/icons/keyboard?f=classic&s=solid on Steam Workshop.]]
version = "1.3"

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

api_version = 10

all_clients_require_mod = false
server_only_mod = false
client_only_mod = true

-- A large enough, somewhat random value to make sure this library loads before consumers; random to avoid conflicts and not FLT_MAX/DBL_MAX to allow other mods load before us, as needed.
-- Don't Starve's mod loader does not actually sort load order based on dependencies:
-- https://forums.kleientertainment.com/forums/topic/147510-help-mod_dependecies-isnt-working-for-me-and-i-have-no-idea-why/?do=findComment&comment=1632937
priority = 999586160

configuration_options = {
}
