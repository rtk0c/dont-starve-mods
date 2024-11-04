-- NOTE: this file runs with GLOBAL environment

----- Notes on Terminology -----
-- Vanilla uses "control" for an action (e.g. Primary, left click by default), we use "keybind".
-- Vanilla uses "control" for a key combination, we use "keychord" for the concept of this. The encoded representations is "input mask".
-- "mapping" is used in place of "keychord" when referring to some stored key sequence in general, rather than as the concept of a key sequence.
-- "input mask" is an uint32 that represents a keychord.
-- "mod[ifiers] mask" is the upper 16 bits of an input mask, that describes the modifier states.
-- "keycode" is the lower 16 bits of an input mask, that describes the non-modifier key. Matches vanilla's KEY_xxx in constants.lua
-- "key" is any on/off stateful input, so it can be keyboard keys or mouse buttons or controller buttons



KeybindLib = {}

-------
-- The table containing all keybinds registered to KeybindLib. The array part contains all keybinds, in order of
-- registration. The hash part contains a lookup table from "<modname>:<id>" to the keybind object.
--
-- To iterate through all registered keybinds, use `for _, keybind in ipairs(KeybindLib.keybind_registry) do ... end`
-- which gives the keybinds in order.
KeybindLib.keybind_registry = {}

-------
-- An internal lookup table of from keycode (lower 16 bits of input mask) to keybind objects. This is automatically
-- maintained on calling `<keybind object>:SetInputMask()`. You may read from this table to implement your own key
-- handlers, if needed.
KeybindLib.keycode_to_keybinds = {}

local keybind_methods = {
  GetInputMask = function(self)
    return self._input_mask
  end,
  SetInputMask = function(self, v)
    local old_keycode = bit.band(bit.rshift(self._input_mask, 32), 0xFFFF)
    self._input_mask = v
    local new_keycode = bit.band(bit.rshift(v, 32), 0xFFFF)

    local old_hooks = KeybindLib.keycode_to_keybinds[old_keycode]
    if old_hooks then
      old_hooks[self] = nil
    end

    if new_keycode ~= 0 then
      local new_hooks = KeybindLib.keycode_to_keybinds[new_keycode]
      if not new_hooks then
        new_hooks = {}
        KeybindLib.keycode_to_keybinds[new_keycode] = new_hooks
      end
      new_hooks[self] = true -- Dummy value, we just want to use it as a hashset
    end
  end,
  IsPressed = function(self)
    local mods_mask = bit.band(self._input_mask, 0xFFFF0000)
    local keycode = bit.band(self._input_mask, 0xFFFF)
    return KeybindLib:GetModifiersMaskNow() == mods_mask and TheInput:IsKeyDown(keycode)
  end,
}
local keybind_metatable = {
  -- Don't provide a __newindex, if users want to insert extra keys, just let it stay local to the keybind object
  -- Similarly if they (for whatever reason) wants to override methods, they also stay local
  __index = keybind_methods,
}

-- Keybind full ID must contain no "=", so that our mapping parser can unambiguously split each line in half, getting
-- the full ID and mapping out.
--
-- We can't enforce some valid modname format, since that comes from DST itself.
-- So we can only cope: escape to get rid of "=", so our parse code won't choke.
--
-- We _can_ enforce keybind ID format, so let's do that.
--
-- (Don't care if modname or keybind ID contains colons, because we're never splitting a full ID apart again, so all
-- that matters is we get an unique string from ComputeKeybindFulLID().)

function KeybindLib:IsKeybindIDValid(keybind_id)
  -- Breakdown of the pattern:
  --   %w      alphanumeric, == /[a-zA-Z0-9]/
  --   %-      escape -
  --   : / _   are themselves
  -- If we match anything that's not these ^^^ characters, it's invalid
  return string.match(keybind_id, "[^%w:/_%-]") == nil
end

function KeybindLib:ComputeKeybindFullID(modname, keybind_id)
  -- Assume keybind ID is valid, so that there is no "="
  return string.gsub(modname, "=", "_") .. ":" .. keybind_id
end

-------
-- @param keybind The keybind object.
-- @tparam string keybind.id An unique identifier for this keybind.
-- @tparam string keybind.modname Your mod's `modname` as registered in `KnownModIndex`. You can retrieve by calling `KnownModIndex:GetModActualName(modinfo.name)`.
-- @tparam string keybind.name A human-readable (and preferrably localized) name for this keybind. For dispaly in UI.
-- @tparam[opt] string keybind.default_mapping The default mapping, in the Keychord Format. See `KeybindLib:InputMaskToString` and `KeybindLib:InputMaskFromString`.
-- @tparam[opt] func keybind.callback Function to be called when the keybind is triggered. If nil, nothing happens when the keychord is pressed.
function KeybindLib:RegisterKeybind(keybind)
  local reg = self.keybind_registry

  if not self:IsKeybindIDValid(keybind.id) then
    error("Invalid keybind ID: must contain only alphanumeric, and _ - : / characters")
  end

  local full_id = self:ComputeKeybindFullID(keybind.modname, keybind.id)
  if reg[full_id] then
    error("A keybind with ID '" .. keybind.id .. "' from mod '" .. keybind.modname .. "' already exists.")
  end

  setmetatable(keybind, keybind_metatable)

  -- Regular .id and .modname are kept the same, so users can retrieve them for their reasons.
  -- (e.g. our keybind mapping screen use modname to get mods' fancy name)
  keybind.full_id = full_id -- Cache for faster access

  local index = #reg + 1
  keybind.index = index

  -- Set field for :GetInputMask() and :SetInputMask()
  keybind._input_mask = 0 -- Mask for unset keybind

  if keybind.default_mapping then
    local im = self:InputMaskFromString(keybind.default_mapping)
    keybind.default_input_mask = im -- Cache the value
    keybind:SetInputMask(im) -- Will be overridden if this keybind is mapped by the user on LoadKeybindMappings()
  else
    keybind.default_mapping = ""
    keybind.default_input_mask = 0
  end

  -- Register for id -> keybind lookup
  reg[full_id] = keybind
  -- Register for ordered iteration
  reg[keybind.index] = keybind

  return keybind
end

-------
-- @tparam string modname Mod's ID which they keybind came from.
-- @tparam string id The keybind's ID to be unregistered.
function KeybindLib:UnregisterKeybind(modname, id)
  local reg = self.keybind_registry
  local keybind = reg[self:ComputeKeybindFullID(modname, id)]
  if keybind then
    keybind:SetInputMask(0) -- Clear entry in the hook table
    reg[id] = nil
    reg[keybind.index] = nil
  end
end


-------
-- Maps keycode into a locale-independent, persistent key name. Not all possible keycodes emitted by C++ code are \
-- stored here, so always check against nil lookup values.
KeybindLib.canon_keycode2string = {
  -- Numpad
  [KEY_KP_0] = "Numpad 0",
  [KEY_KP_1] = "Numpad 1",
  [KEY_KP_2] = "Numpad 2",
  [KEY_KP_3] = "Numpad 3",
  [KEY_KP_4] = "Numpad 4",
  [KEY_KP_5] = "Numpad 5",
  [KEY_KP_6] = "Numpad 6",
  [KEY_KP_7] = "Numpad 7",
  [KEY_KP_8] = "Numpad 8",
  [KEY_KP_9] = "Numpad 9",
  [KEY_KP_PERIOD] = "Numpad .",
  [KEY_KP_DIVIDE] = "Numpad /",
  [KEY_KP_MULTIPLY] = "Numpad *",
  [KEY_KP_MINUS] = "Numpad -",
  [KEY_KP_PLUS] = "Numpad +",
  [KEY_KP_ENTER] = "Numpad Enter",
  [KEY_KP_EQUALS] = "Numpad =", -- Vanilla commented this one out in strings.lua; because no majorly in use keyboard produces this key?

  -- Misc
  [KEY_BACKSPACE] = "Backspace",
  [KEY_SPACE] = "Space",
  [KEY_ENTER] = "Enter",
  [KEY_ESCAPE] = "Esc",
  [KEY_TAB] = "Tab",
  [KEY_HOME] = "Home",
  [KEY_INSERT] = "Ins",
  [KEY_DELETE] = "Del",
  [KEY_END] = "End",
  [KEY_PAGEUP] = "PgUp",
  [KEY_PAGEDOWN] = "PgDn",
  [KEY_PAUSE] = "Pause",
  [KEY_PRINT] = "Print",
  [KEY_CAPSLOCK] = "CapsLock",
  [KEY_SCROLLOCK] = "ScrollLock",

  -- Modifiers
  [KEY_RSHIFT]  = "RShift",
  [KEY_LSHIFT]  = "LShift",
  [KEY_RCTRL]  = "RCtrl",
  [KEY_LCTRL]  = "LCtrl",
  [KEY_RALT]  = "RAlt",
  [KEY_LALT]  = "LAlt",
  [KEY_LSUPER] = "LSuper",
  [KEY_RSUPER] = "RSuper",
  -- These seems to be amalganation of the left/right keys done in the C++
  -- Don't store them. They should not be used for keybind.
  --[[
  [KEY_ALT] = "Alt",
  [KEY_CTRL] = "Ctrl",
  [KEY_SHIFT] = "Shift",
  --]]

  [KEY_MINUS] = "-",
  [KEY_EQUALS] = "=",
  [KEY_PERIOD] = ".",
  [KEY_SLASH] = "/",
  [KEY_SEMICOLON] = ";",
  [KEY_LEFTBRACKET] = "[",
  [KEY_BACKSLASH] = "\\",
  [KEY_RIGHTBRACKET] = "]",
  [KEY_TILDE] = "`",
  [KEY_A] = "A",
  [KEY_B] = "B",
  [KEY_C] = "C",
  [KEY_D] = "D",
  [KEY_E] = "E",
  [KEY_F] = "F",
  [KEY_G] = "G",
  [KEY_H] = "H",
  [KEY_I] = "I",
  [KEY_J] = "J",
  [KEY_K] = "K",
  [KEY_L] = "L",
  [KEY_M] = "M",
  [KEY_N] = "N",
  [KEY_O] = "O",
  [KEY_P] = "P",
  [KEY_Q] = "Q",
  [KEY_R] = "R",
  [KEY_S] = "S",
  [KEY_T] = "T",
  [KEY_U] = "U",
  [KEY_V] = "V",
  [KEY_W] = "W",
  [KEY_X] = "X",
  [KEY_Y] = "Y",
  [KEY_Z] = "Z",
  [KEY_F1] = "F1",
  [KEY_F2] = "F2",
  [KEY_F3] = "F3",
  [KEY_F4] = "F4",
  [KEY_F5] = "F5",
  [KEY_F6] = "F6",
  [KEY_F7] = "F7",
  [KEY_F8] = "F8",
  [KEY_F9] = "F9",
  [KEY_F10] = "F10",
  [KEY_F11] = "F11",
  [KEY_F12] = "F12",

  [KEY_UP] = "Up",
  [KEY_DOWN] = "Down",
  [KEY_RIGHT] = "Right",
  [KEY_LEFT] = "Left",

  [KEY_0] = "0",
  [KEY_1] = "1",
  [KEY_2] = "2",
  [KEY_3] = "3",
  [KEY_4] = "4",
  [KEY_5] = "5",
  [KEY_6] = "6",
  [KEY_7] = "7",
  [KEY_8] = "8",
  [KEY_9] = "9",

  [MOUSEBUTTON_LEFT] = "Mouse Left",
  [MOUSEBUTTON_RIGHT] = "Mouse Right",
  [MOUSEBUTTON_MIDDLE] = "Mouse Middle",
  [1005] = "Mouse Button 4",
  [1006] = "Mouse Button 5",
  [MOUSEBUTTON_SCROLLUP] = "Mouse Scroll Up",
  [MOUSEBUTTON_SCROLLDOWN] = "Mouse Scroll Down",
}

-------
-- A reverse lookup table going from key name to keycode.
-- @see KeybindLib.canon_keycode2string
KeybindLib.canon_string2keycode = {}

do
  local tbl = KeybindLib.canon_string2keycode
  for keycode, name in pairs(KeybindLib.canon_keycode2string) do
    tbl[name] = keycode
  end
end



-- These are local because which bits are which is an implementation detail.
-- Consider them private.
local MOD_LCTRL_BIT = 31
local MOD_LSHIFT_BIT = 30
local MOD_LALT_BIT = 29
local MOD_LSUPER_BIT = 28
local MOD_RCTRL_BIT = 27
local MOD_RSHIFT_BIT = 26
local MOD_RALT_BIT = 25
local MOD_RSUPER_BIT = 24

KeybindLib.MODIFIER_KEYS = {
  [KEY_RSHIFT] = { control = "Shift", bit = MOD_RSHIFT_BIT },
  [KEY_LSHIFT] = { control = "Shift", bit = MOD_LSHIFT_BIT },
  [KEY_RCTRL] = { control = "Control", bit = MOD_RCTRL_BIT },
  [KEY_LCTRL] = { control = "Control", bit = MOD_LCTRL_BIT },
  [KEY_RALT] = { control = "Alt", bit = MOD_RALT_BIT },
  [KEY_LALT] = { control = "Alt", bit = MOD_LALT_BIT },
  [KEY_LSUPER] = { control = "Super", bit = MOD_LSUPER_BIT },
  [KEY_RSUPER] = { control = "Super", bit = MOD_RSUPER_BIT },
  -- We don't ever use these combined modifier keycodes in a keychord
  --[[
  [KEY_ALT] = false,
  [KEY_CTRL] = false,
  [KEY_SHIFT] = false,
  --]]
}

-------
-- Compute the modifiers mask pressed at this moment.
-- @treturn number A Lua number, with the upper 16 bits filled as the current modifiers mask.
function KeybindLib:GetModifiersMaskNow()
  local res = 0
  -- TODO it seems like on linux (wayland, DST runs in xwayland; don't know about native X11)
  --      right alt, right shift, and _sometimes_ right control can't be detected
  --      it seems like whether or not super works depends on the window manager 
  for mod_keycode, info in pairs(self.MODIFIER_KEYS) do
    if TheInput:IsKeyDown(mod_keycode) then
      res = bit.bor(res, bit.lshift(1, info.bit))
    end
  end
  return res
end

local function TestBit(mask, n)
  return bit.band(bit.rshift(mask, n), 1) == 1
end

-------
-- Parse input mask from a string in the Keychord Format.
-- @see KeybindLib:InputMaskToString
function KeybindLib:InputMaskFromString(str)
  -- print("InputMaskFromString(): '"..str.."'")

  local mods_tbl = self.MODIFIER_KEYS
  local fromstr_tbl = self.canon_string2keycode

  local input_mask = 0
  local i = 1
  local key_name
  while true do
    local pos, j = string.find(str, " + ", i, true)
    if pos then
      -- string.sub is gets [start,end] rather than the conventional [start,end)
      -- so we can't avoid doing arithmetic on `pos`, and if it's nil that will error.
      key_name = string.sub(str, i, pos-1)
      local mod = mods_tbl[fromstr_tbl[key_name]]
      if mod then
        input_mask = bit.bor(input_mask, bit.lshift(1, mod.bit))
      end
      i = j + 1
    else
      key_name = string.sub(str, i)
      break
    end
  end

  local keycode = fromstr_tbl[key_name]
  if not keycode then
    keycode = tonumber(key_name)
    if not keycode then
      error("Primary key in string '" .. str .. "' is neither a valid key name, nor a keycode")
    end
  end
  input_mask = bit.bor(input_mask, bit.band(keycode, 0xFFFF))

  return input_mask
end

local function InputMaskToString(v, tostr_tbl)
  local keycode = bit.band(bit.rshift(v, 32), 0xFFFF)
  if keycode == 0 then
    return ""
  end

  local pieces = {}
  for mod_keycode, info in pairs(KeybindLib.MODIFIER_KEYS) do
    if TestBit(v, info.bit) then
      table.insert(pieces, tostr_tbl[mod_keycode])
    end
  end

  local key_name = tostr_tbl[keycode]
  table.insert(pieces, key_name and key_name or tostring(keycode))

  return table.concat(pieces, " + ")
end

-------
-- Stringify input mask in the Keychord Format.
-- @see KeybindLib:InputMaskFromString
function KeybindLib:InputMaskToString(v)
  return InputMaskToString(v, self.canon_keycode2string)
end

-------
-- Stringify input mask in in the current display language, for humans. This is not in the Keychord Format, and is
-- NOT compatible with `KeybindLib:InputMaskFromString`.
function KeybindLib:LocalizeInputMask(v)
  return InputMaskToString(v, STRINGS.UI.CONTROLSSCREEN.INPUTS[1])
end



local function InputHandler(keycode, down)
  if down then return end

  local keybind_list = KeybindLib.keycode_to_keybinds[keycode]
  if not keybind_list then return end

  local mod_mask = KeybindLib:GetModifiersMaskNow()
  local input_mask = bit.bor(mod_mask, keycode)

  for keybind, _ in pairs(keybind_list) do
    if keybind:GetInputMask() == input_mask and keybind.callback then
      keybind.callback()
    end
  end
end

TheInput:AddKeyHandler(InputHandler)
TheInput:AddMouseButtonHandler(InputHandler) -- Ignore the 3rd (x) and 4rd (y) arguments



-------
-- Load keybind mappings from the "KeybindLib_Mappings" file in DST's mod config folder. Overrides current values in
-- `keybind_registry`.
function KeybindLib:LoadKeybindMappings()
  local path = KnownModIndex:GetModConfigurationPath() .. "KeybindLib_Mappings"
  TheSim:GetPersistentString(path, function(load_success, str)
    if not load_success then
      print("[KeybindLib] Failed to load mod keybinds. You will get default keybinds.")
      return
    end

    -- Breakdown of the pattern:
    --   ([^=\r\n]*)   Full ID part
    --   =             Assignment symbol
    --   ([^\r\n]*)    Mapping part
    --   [\r\n]\n?     Line break, handle either CRLF or LF
    --                 note GetPersistentString() does not normalize, but SetPersistentString() will convert LF to CRLF
    --
    -- We specifically want to use greedy match for performance:
    -- The subpatterns all look like /[^k]*k/ where k is some characters. This construction makes sure that no
    -- backtracking will ever happen, since whenever the parser reaches some k, it will immediately exit the greedy
    -- subpattern. If we were to use non-greedy, the parser has to try the subpattern following non-greedy at every
    -- step.
    --
    -- Greedy and non-greedy also should match the exact same thing, since the repetition cannot match across any k.
    for full_id, mapping in string.gmatch(str, "([^=\r\n]*)=([^\r\n]*)[\r\n]\n?") do
      print("'"..full_id.."' = '" .. mapping .. "'")
        local keybind = self.keybind_registry[full_id]
      if keybind then
        keybind:SetInputMask(self:InputMaskFromString(mapping))
      end
    end
  end)
end

-------
-- Save keybind mappings to the "KeybindLib_Mappings" file in DST's mod config folder.
function KeybindLib:SaveKeybindMappings()
  local saved_kbd = {}
  for _, kbd in ipairs(self.keybind_registry) do
    local im = kbd:GetInputMask()
    if im ~= kbd.default_input_mask then
      table.insert(saved_kbd, kbd.full_id .. "=" .. self:InputMaskToString(im))
    end
  end

  -- Force final new line when calling table.concat()
  table.insert(saved_kbd, "")

  local path = KnownModIndex:GetModConfigurationPath() .. "KeybindLib_Mappings"
  -- Don't zlib compress the string, it's not big, and we want the user to be able to edit it with a text editor
  TheSim:SetPersistentString(path, table.concat(saved_kbd, "\n"), false)
end
