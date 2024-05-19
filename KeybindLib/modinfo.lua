name = "[API] KeybindLib"
author = "rtk0c"
description = [[Library for handling keybinds, in a sane manner.

For users: you can go to Options > Mod Keybinds in the main menu or in the in-game esc menu, and configure mods' keybinds with a system similar to vanilla's control system.
If you wish to backup your keybinds or edit them by hand, it is stored in a plain text file at <DST data folder>/client_save/mod_config_data/KeybindLib_Mappings.
Note that in this file, the spaces around the "+" symbol are required. There must be no spaces around the "=" symbol. There must be no final newline in the file.

For developers: see github.com/rtk0c/dont-starve-mods/tree/master/KeybindLib for documentation.]]
version = "1.0"

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

api_version = 10

all_clients_require_mod = false
server_only_mod = false
client_only_mod = true

configuration_options = {
}
