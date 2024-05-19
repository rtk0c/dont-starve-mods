# KeybindLib

A library for handling keybinds. See LDoc comments in [`scripts/keybind.lua`](./scripts/keybind.lua) for how to use each API function.

For users: you can go to Options > Mod Keybinds in the main menu or in the in-game esc menu, and configure mods' keybinds with a system similar to vanilla's control system.
If you wish to backup your keybinds or edit them by hand, it is stored in a plain text file at `<DST data folder>/client_save/mod_config_data/KeybindLib_Mappings`.
Note that in this file, the spaces around the "+" symbol are required. There must be no spaces around the "=" symbol. There must be no final newline in the file.

## Quickstart

In your `modmain.lua`,
```lua
local modname = GLOBAL.KnownModIndex:GetModActualName(modinfo.name)

GLOBAL.KeybindLib:RegisterKeybind({
  id = "my_awesome_keybind",
  name = "Awesome Keybind",
  description = "This is a keybind for my mod. Triggering it does cool things.",
  -- This string has to be in the format of:
  --     [<mod> + [mod + [...]]] <key>
  -- where <mod> is one of LCtrl, LShift, LAlt, LSuper, and the `R`ight versions thereof (see `KEY_NAME_TO_MODIFIER_BIT` in keybind.lua),
  -- and <key> is a key name (see `KeybindLib.KEY_INFO_TABLE` in keybind.lua).
  --
  -- Alternatively, you can leave it out (= nil), and the keybind will be unset by default.
  default_mapping = "LCtrl + H",
  modid = modname,
  callback = function()
  	GLOBAL.ThePlayer.components.talker:Say("Hello, world!")
  end,
})
```

And the user can remap your keybind just like vanilla controls. The callback will be called automatically whenever the mapping is pressed, _regardless of context_. You will need to check for HUD state, whether or not `TheSim` is running, etc. yourself to do the correct thing.

# Details

## Notes on Terminology
- "keybind" is a triggerable action, the thing you register with `KeybindLib:RegisterKeybind()`. It's a "slot" for a key sequence to be mapped to.
- "keychord" is used for the concept of a key sequence (or a key combination, if you like that wording). The encoded representations is "input mask".
- "mapping" is used in place of "keychord" when referring to some stored key sequence in general, rather than as the concept of a key sequence.
- "input mask" is an uint32 that represents a keychord.
- "mod[ifiers] mask" is the upper 16 bits of an input mask, that describes the modifier states.
- "keycode" is the lower 16 bits of an input mask, that describes the non-modifier key. Matches vanilla's KEY_xxx in `constants.lua`.
- "key" is any on/off stateful input, so it can be keyboard keys or mouse buttons or controller buttons.
