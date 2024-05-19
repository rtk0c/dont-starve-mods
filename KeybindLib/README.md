# KeybindLib

A library for handling keybinds. Let players configure keybinds just like vanilla's Options > Controls menu!

**For modders:** when you register a keybind with this library, these automatically happens: (See [Quickstart](#quickstart))
1. An entry in the Options > Mod Keybinds screen is added for easy remapping for the player.
2. The callback you supply when registering is called when the player presses the configured key sequence. In any context--even in the main menu, for example, if your mod is loaded (again see README.md, caveats section).

**For players:** you can go to Options > Mod Keybinds in the main menu or in the in-game esc menu, and configure mods' keybinds with a system similar to vanilla's control system.
If you wish to backup your keybinds or edit them by hand, it is stored in a plain text file at `<DST data folder>/client_save/mod_config_data/KeybindLib_Mappings`.
Note that in this file, the spaces around the "+" symbol are required. There must be no spaces around the "=" symbol. There must be a final newline in the file.

![](https://steamuserimages-a.akamaihd.net/ugc/2477620729421146696/5BD7CBCF026D8EFDF3FB3C0827DE5A3326D93EB7/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false)
![](https://steamuserimages-a.akamaihd.net/ugc/2477620729421146683/B517F25126F27C62E09F4F5C7FDD7BD2356FFD27/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false)
![](https://steamuserimages-a.akamaihd.net/ugc/2477620729421146691/DCEB2828494ED468A863157B1014B6E280B9EC97/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false)

This mod is published on Steam Workshop. https://steamcommunity.com/sharedfiles/filedetails/?id=3250212696  
This mod is published on Klei forums. https://forums.kleientertainment.com/forums/topic/156221-api-keybindlib-configure-keybinds-just-like-vanillas-options-controls-menu/

## API Documentation

See LDoc comments in [`scripts/keybind.lua`](./scripts/keybind.lua) for how to use each API function. Every API function is defined in this file, all other files are implementation details.

## Quickstart

Make your mod depend on this with `mod_dependencies` in your `modinfo.lua`, and (if yours is published on Steam Workshop) add [this mod](https://steamcommunity.com/sharedfiles/filedetails/?id=3250212696) as a required item. In your `modmain.lua`,
```lua
local modname = GLOBAL.KnownModIndex:GetModActualName(modinfo.name)

GLOBAL.KeybindLib:RegisterKeybind({
  -- See Notes and Caveats for the requirements of these fields
  id = "my_awesome_keybind",
  name = "Awesome Keybind",
  description = "This is a keybind for my mod. Triggering it does cool things.",
  default_mapping = "LCtrl + H",
  modid = modname,
  callback = function()
  	GLOBAL.ThePlayer.components.talker:Say("Hello, world!")
  end,
})
```

And the user can remap your keybind just like vanilla controls.

## Notes and Caveats

- The `callback` you supply to `RegisterKeybind()` will be called whenever the mapping is pressed, _regardless of context_. You will need to check for HUD state, whether or not `TheSim` is running, etc. yourself to do the correct thing.
- `callback` may be nil, in which case nothing happens when the player triggers the keybind.
- Mod ID `modid` has to be the result of `KnownModIndex:GetModActualName(modid.name)`. This is so that it is persistent even if you change your mod's fancy name (the one displayed to the player in the Mods screen, i.e. `modinfo.name`), because it is used to store your keybind mappings on disk. I call it mod ID instead of "modname" to avoid confusion with `modinfo.name`.
- Keybind `id` can only contain alphanumeric characters or one of `/:-_`. See [`IsKeybindIDValid()`](https://github.com/rtk0c/dont-starve-mods/blob/master/KeybindLib/scripts/keybind.lua#L71-L78). Used to store your keybind mapping, do not localize.
- Keybind `name` and `description` is shown to the user in Options > Mod Keybinds. Localize them if you can.
- Keybind `default_mapping` has to be in the format of `[<mod> + [mod + [...]]] <key>`
  - `<mod>` is one of LCtrl, LShift, LAlt, LSuper, and the **R**ight versions thereof (see `KEY_NAME_TO_MODIFIER_BIT` in keybind.lua)
  - `<key>` is a key name (see `KeybindLib.KEY_INFO_TABLE` in keybind.lua)
  - Alternatively, you can leave it out (= nil), and the keybind will be unset by default

# About Source Code

## Notes on Terminology
- "keybind" is a triggerable action, the thing you register with `KeybindLib:RegisterKeybind()`. It's a "slot" for a key sequence to be mapped to.
- "keychord" is used for the concept of a key sequence (or a key combination, if you like that wording). The encoded representations is "input mask".
- "mapping" is used in place of "keychord" when referring to some stored key sequence in general, rather than as the concept of a key sequence.
- "input mask" is an uint32 that represents a keychord.
- "mod[ifiers] mask" is the upper 16 bits of an input mask, that describes the modifier states.
- "keycode" is the lower 16 bits of an input mask, that describes the non-modifier key. Matches vanilla's KEY_xxx in `constants.lua`.
- "key" is any on/off stateful input, so it can be keyboard keys or mouse buttons or controller buttons.
