# KeybindMagic
English | [中文](./README.zh.md)

KeybindMagic is a single-file, vendorable utility for adding keybinds that are easily user-rebindable. Keybinds will appaer both in Options > Controls and in Mods > \[your mod\] > Configuration Options. The config options spinner will be automatically replaced with one similar to the one found in Options.

This utility is designed with Don't Starve Together's mod loader's weak dependency handling abilities in mind, so it can work fine even if multiple mods vendored it and ran their own copy.

## Limitations
Because config options can only take value from a limited set of values, the keybinds can only be bound to a single key, modifiers is not supported.

## Quickstart
Copy `keybind_magic.lua` to your mod. Add keybinds like demoed in `modinfo.lua`, and use the keybind values like demoed in `modmain.lua`.
