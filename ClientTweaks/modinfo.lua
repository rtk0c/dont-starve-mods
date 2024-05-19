name = "Client Tweaks"
id = "rtk0c.DST_ClientTweaks" --unofficial field
author = "rtk0c"
description = "Various client tweaks."
version = "1.0"

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

api_version = 10

all_clients_require_mod = false
server_only_mod = false
client_only_mod = true

mod_dependencies = {
	-- [API] KeybindLib
	-- TODO fill in when KeybindLib is uploaded
    { workshop = "workshop-XXXX", },
}



-------- Non-user-facing configuration options --------
-- These needs a reset (running modmain.lua again) to take effect

-- Expose development utilities
opt_dev_mode = true
-- If true, wraps game-facing callbacks in an error handler that merely logs the error without crashing
-- Disable this in production environment, or want to test mod in "real world conditions"
opt_safe_mode = true



configuration_options = {
}
