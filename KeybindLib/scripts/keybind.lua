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
-- registration. The hash part contains a lookup table from "<modid>:<id>" to the keybind object.
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
}
local keybind_metatable = {
  -- Don't provide a __newindex, if users want to insert extra keys, just let it stay local to the keybind object
  -- Similarly if they (for whatever reason) wants to override methods, they also stay local
  __index = keybind_methods,
}

-- Keybind full ID must contain no "=", so that our mapping parser can unambiguously split each line in half, getting
-- the full ID and mapping out.
--
-- We can't enforce some valid modid format, since that comes from DST itself.
-- So we can only cope: escape to get rid of "=", so our parse code won't choke.
--
-- We _can_ enforce keybind ID format, so let's do that.
--
-- (Don't care if modid or keybind ID contains colons, because we're never splitting a full ID apart again, so all
-- that matters is we get an unique string from ComputeKeybindFulLID().)

function KeybindLib:IsKeybindIDValid(keybind_id)
  -- Breakdown of the pattern:
  --   %w      alphanumeric, == /[a-zA-Z0-9]/
  --   %-      escape -
  --   : / _   are themselves
  -- If we match anything that's not these ^^^ characters, it's invalid
  return string.match(keybind_id, "[^%w:/_%-]") == nil
end

function KeybindLib:ComputeKeybindFullID(modid, keybind_id)
  -- Assume keybind ID is valid, so that there is no "="
  return string.gsub(modid, "=", "_") .. ":" .. keybind_id
end

-------
-- @param keybind The keybind object.
-- @tparam string keybind.id An unique identifier for this keybind.
-- @tparam string keybind.modid Your mod's `modname` as registered in `KnownModIndex`. You can retrieve by calling `KnownModIndex:GetModActualName(modinfo.name)`.
-- @tparam string keybind.name A human-readable (and preferrably localized) name for this keybind. For dispaly in UI.
-- @tparam[opt] string keybind.default_mapping The default mapping, in the Keychord Format. See `KeybindLib:InputMaskToString` and `KeybindLib:InputMaskFromString`.
-- @tparam[opt] func keybind.callback Function to be called when the keybind is triggered. If nil, nothing happens when the keychord is pressed.
function KeybindLib:RegisterKeybind(keybind)
  local reg = self.keybind_registry

  if not self:IsKeybindIDValid(keybind.id) then
    error("Invalid keybind ID: must contain only alphanumeric, and _ - : / characters")
  end

  local full_id = self:ComputeKeybindFullID(keybind.modid, keybind.id)
  if reg[full_id] then
    error("A keybind with ID '" .. keybind.id .. "' from mod '" .. keybind.modid .. "' already exists.")
  end

  setmetatable(keybind, keybind_metatable)

  -- Regular .id and .modid are kept the same, so users can retrieve them for their reasons.
  -- (e.g. our keybind mapping screen use modid to get mods' fancy name)
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
end

-------
-- @tparam string modid Mod's ID which they keybind came from.
-- @tparam string id The keybind's ID to be unregistered.
function KeybindLib:UnregisterKeybind(modid, id)
  local reg = self.keybind_registry
  local keybind = reg[self:ComputeKeybindFullID(modid, id)]
  if keybind then
    keybind:SetInputMask(0) -- Clear entry in the hook table
    reg[id] = nil
    reg[keybind.index] = nil
  end
end



-- TODO replace this with STRINGS.CONTROLSSCREEN.CONTROLS.INPUTS
-------
-- Maps keycode into a key information table. Not all possible keycodes emitted by C++ code are stored
-- here, so always check against nil lookup values.
KeybindLib.KEY_INFO_TABLE = {
  [KEY_KP_0] = { name = "Numpad 0", category = "numpad" },
  [KEY_KP_1] = { name = "Numpad 1", category = "numpad" },
  [KEY_KP_2] = { name = "Numpad 2", category = "numpad" },
  [KEY_KP_3] = { name = "Numpad 3", category = "numpad" },
  [KEY_KP_4] = { name = "Numpad 4", category = "numpad" },
  [KEY_KP_5] = { name = "Numpad 5", category = "numpad" },
  [KEY_KP_6] = { name = "Numpad 6", category = "numpad" },
  [KEY_KP_7] = { name = "Numpad 7", category = "numpad" },
  [KEY_KP_8] = { name = "Numpad 8", category = "numpad" },
  [KEY_KP_9] = { name = "Numpad 9", category = "numpad" },
  [KEY_KP_PERIOD] = { name = "Numpad .", category = "numpad" },
  [KEY_KP_DIVIDE] = { name = "Numpad /", category = "numpad" },
  [KEY_KP_MULTIPLY] = { name = "Numpad *", category = "numpad" },
  [KEY_KP_MINUS] = { name = "Numpad -", category = "numpad" },
  [KEY_KP_PLUS] = { name = "Numpad +", category = "numpad" },
  [KEY_KP_ENTER] = { name = "Numpad Enter", category = "numpad" },
  [KEY_KP_EQUALS] = { name = "Numpad =", category = "numpad" },

  -- Misc category
  [KEY_MINUS] = { name = "-" },
  [KEY_EQUALS] = { name = "=" },
  [KEY_BACKSPACE] = { name = "Backspace" },
  [KEY_SPACE] = { name = "Space" },
  [KEY_ENTER] = { name = "Enter" },
  [KEY_ESCAPE] = { name = "Esc" },
  [KEY_TAB] = { name = "Tab" },
  [KEY_HOME] = { name = "Home" },
  [KEY_INSERT] = { name = "Ins" },
  [KEY_DELETE] = { name = "Del" },
  [KEY_END] = { name = "End" },
  [KEY_PAGEUP] = { name = "PgUp" },
  [KEY_PAGEDOWN] = { name = "PgDn" },
  [KEY_PAUSE] = { name = "Pause" },
  [KEY_PRINT] = { name = "Print" },

  [KEY_CAPSLOCK] = { name = "CapsLock", category = "mod" },
  [KEY_SCROLLOCK] = { name = "ScrollLock", category = "mod" },
  [KEY_RSHIFT]  = { name = "RShift", category = "mod" },
  [KEY_LSHIFT]  = { name = "LShift", category = "mod" },
  [KEY_RCTRL]  = { name = "RCtrl", category = "mod" },
  [KEY_LCTRL]  = { name = "LCtrl", category = "mod" },
  [KEY_RALT]  = { name = "RAlt", category = "mod" },
  [KEY_LALT]  = { name = "LAlt", category = "mod" },
  [KEY_LSUPER] = { name = "LSuper", category = "mod" },
  [KEY_RSUPER] = { name = "RSuper", category = "mod" },
  -- These seems to be amalganation of the left/right keys done in the C++ later
  --[[
  [KEY_ALT] = { name = "Alt", category = "mod" },
  [KEY_CTRL] = { name = "Ctrl", category = "mod" },
  [KEY_SHIFT] = { name = "Shift", category = "mod" },
  --]]

  [KEY_PERIOD] = { name = "." },
  [KEY_SLASH] = { name = "/" },
  [KEY_SEMICOLON] = { name = ";" },
  [KEY_LEFTBRACKET] = { name = "[" },
  [KEY_BACKSLASH] = { name = "\\" },
  [KEY_RIGHTBRACKET] = { name = "]" },
  [KEY_TILDE] = { name = "`" },
  [KEY_A] = { name = "A", category = "letter" },
  [KEY_B] = { name = "B", category = "letter" },
  [KEY_C] = { name = "C", category = "letter" },
  [KEY_D] = { name = "D", category = "letter" },
  [KEY_E] = { name = "E", category = "letter" },
  [KEY_F] = { name = "F", category = "letter" },
  [KEY_G] = { name = "G", category = "letter" },
  [KEY_H] = { name = "H", category = "letter" },
  [KEY_I] = { name = "I", category = "letter" },
  [KEY_J] = { name = "J", category = "letter" },
  [KEY_K] = { name = "K", category = "letter" },
  [KEY_L] = { name = "L", category = "letter" },
  [KEY_M] = { name = "M", category = "letter" },
  [KEY_N] = { name = "N", category = "letter" },
  [KEY_O] = { name = "O", category = "letter" },
  [KEY_P] = { name = "P", category = "letter" },
  [KEY_Q] = { name = "Q", category = "letter" },
  [KEY_R] = { name = "R", category = "letter" },
  [KEY_S] = { name = "S", category = "letter" },
  [KEY_T] = { name = "T", category = "letter" },
  [KEY_U] = { name = "U", category = "letter" },
  [KEY_V] = { name = "V", category = "letter" },
  [KEY_W] = { name = "W", category = "letter" },
  [KEY_X] = { name = "X", category = "letter" },
  [KEY_Y] = { name = "Y", category = "letter" },
  [KEY_Z] = { name = "Z", category = "letter" },
  [KEY_F1] = { name = "F1", category = "fn" },
  [KEY_F2] = { name = "F2", category = "fn" },
  [KEY_F3] = { name = "F3", category = "fn" },
  [KEY_F4] = { name = "F4", category = "fn" },
  [KEY_F5] = { name = "F5", category = "fn" },
  [KEY_F6] = { name = "F6", category = "fn" },
  [KEY_F7] = { name = "F7", category = "fn" },
  [KEY_F8] = { name = "F8", category = "fn" },
  [KEY_F9] = { name = "F9", category = "fn" },
  [KEY_F10] = { name = "F10", category = "fn" },
  [KEY_F11] = { name = "F11", category = "fn" },
  [KEY_F12] = { name = "F12", category = "fn" },

  [KEY_UP] = { name = "Up", category = "arrow" },
  [KEY_DOWN] = { name = "Down", category = "arrow" },
  [KEY_RIGHT] = { name = "Right", category = "arrow" },
  [KEY_LEFT] = { name = "Left", category = "arrow" },

  [KEY_0] = { name = "0", category = "number" },
  [KEY_1] = { name = "1", category = "number" },
  [KEY_2] = { name = "2", category = "number" },
  [KEY_3] = { name = "3", category = "number" },
  [KEY_4] = { name = "4", category = "number" },
  [KEY_5] = { name = "5", category = "number" },
  [KEY_6] = { name = "6", category = "number" },
  [KEY_7] = { name = "7", category = "number" },
  [KEY_8] = { name = "8", category = "number" },
  [KEY_9] = { name = "9", category = "number" },

  [MOUSEBUTTON_LEFT] = { name = "Mouse Left", category = "mouse" },
  [MOUSEBUTTON_RIGHT] = { name = "Mouse Right", category = "mouse" },
  [MOUSEBUTTON_MIDDLE] = { name = "Mouse Middle", category = "mouse" },
  [1005] = { name = "Mouse Button 4", category = "mouse" },
  [1006] = { name = "Mouse Button 5", category = "mouse" },
  [MOUSEBUTTON_SCROLLUP] = { name = "Mouse Scroll Up", category = "mouse" },
  [MOUSEBUTTON_SCROLLDOWN] = { name = "Mouse Scroll Down", category = "mouse" },
}

-------
-- A reverse lookup table going from key name to keycode. If you need to go from key name to key info, write
-- `KeybindLib.KEY_INFOTABLE[KeybindLib.KEY_NAME_LOOKUP_TABLE[your_keycode]]`.
-- @see KeybindLib.KEY_INFO_TABLE
KeybindLib.KEY_NAME_LOOKUP_TABLE = {}

do
  local key2info = KeybindLib.KEY_INFO_TABLE
  local name2key = KeybindLib.KEY_NAME_LOOKUP_TABLE

  for keycode, info in pairs(key2info) do
    name2key[info.name] = keycode
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

-------
-- Compute the modifiers mask pressed at this moment.
-- @treturn number A Lua number, with the upper 16 bits filled as the current modifiers mask.
function KeybindLib:GetModifiersMaskNow()
  return bit.bor(
    TheInput:IsKeyDown(KEY_LCTRL) and bit.lshift(1, MOD_LCTRL_BIT) or 0,
    TheInput:IsKeyDown(KEY_LSHIFT) and bit.lshift(1, MOD_LSHIFT_BIT) or 0,
    -- FIXME LAlt and RAlt are not being detected right now
    TheInput:IsKeyDown(KEY_LALT) and bit.lshift(1, MOD_LALT_BIT) or 0,
    TheInput:IsKeyDown(KEY_LSUPER) and bit.lshift(1, MOD_LSUPER_BIT) or 0,
    TheInput:IsKeyDown(KEY_RCTRL) and bit.lshift(1, MOD_RCTRL_BIT) or 0,
    TheInput:IsKeyDown(KEY_RSHIFT) and bit.lshift(1, MOD_RSHIFT_BIT) or 0,
    TheInput:IsKeyDown(KEY_RALT) and bit.lshift(1, MOD_RALT_BIT) or 0,
    TheInput:IsKeyDown(KEY_RSUPER) and bit.lshift(1, MOD_RSUPER_BIT) or 0)
end

local function TestBit(mask, n)
  return bit.band(bit.rshift(mask, n), 1) == 1
end

local KEY_NAME_TO_MODIFIER_BIT = {
  LCtrl = MOD_LCTRL_BIT,
  LShift = MOD_LSHIFT_BIT,
  LAlt = MOD_LALT_BIT,
  LSuper = MOD_LSUPER_BIT,
  RCtrl = MOD_RCTRL_BIT,
  RShift = MOD_RSHIFT_BIT,
  RAlt = MOD_RALT_BIT,
  RSuper = MOD_RSUPER_BIT,
}

-------
-- Parse input mask from a string in the Keychord Format.
-- @see KeybindLib:InputMaskToString
function KeybindLib:InputMaskFromString(str)
  -- print("InputMaskFromString(): '"..str.."'")

  local input_mask = 0
  local i = 1
  local key_name
  while true do
    local pos, j = string.find(str, " + ", i, true)
    if pos then
      -- string.sub is gets [start,end] rather than the conventional [start,end)
      -- so we can't avoid doing arithmetic on `pos`, and if it's nil that will error.
      key_name = string.sub(str, i, pos-1)
      input_mask = bit.bor(input_mask, bit.lshift(1, KEY_NAME_TO_MODIFIER_BIT[key_name]))
      i = j + 1
    else
      key_name = string.sub(str, i)
      break
    end
  end

  local keycode = self.KEY_NAME_LOOKUP_TABLE[key_name]
  if keycode then
    input_mask = bit.bor(input_mask, keycode)
  end

  return input_mask
end

-------
-- Stringify input mask in the Keychord Format.
-- @see KeybindLib:InputMaskFromString
function KeybindLib:InputMaskToString(v)
  local keycode = bit.band(bit.rshift(v, 32), 0xFFFF)
  if keycode == 0 then
    return ""
  end

  local pieces = {}
  local function F(bit, str)
    if TestBit(v, bit) then
      table.insert(pieces, str)
    end
  end
  F(MOD_LCTRL_BIT, "LCtrl")
  F(MOD_LSHIFT_BIT, "LShift")
  F(MOD_LALT_BIT, "LAlt")
  F(MOD_LSUPER_BIT, "LSuper")
  F(MOD_RCTRL_BIT, "RCtrl")
  F(MOD_RSHIFT_BIT, "RShift")
  F(MOD_RALT_BIT, "RAlt")
  F(MOD_RSUPER_BIT, "RSuper")

  local key_info = self.KEY_INFO_TABLE[keycode]
  table.insert(pieces, key_info and key_info.name or "<unknown>")

  return table.concat(pieces, " + ")
end



local keychord_capture_callback = nil

function KeybindLib:BeginKeychordCapture(callback)
  keychord_capture_callback = callback
end

function KeybindLib:CancelKeychordCapture()
  keychord_capture_callback = nil
end

local function HandleKeyTrigger(keycode)
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

TheInput:AddKeyHandler(function(key, down)
  if not down then
    HandleKeyTrigger(key)
  end

  if not keychord_capture_callback then return end

  -- NOTE: this key handler only takes keyboard inputs
  -- Keep taking input until a key release
  local key_info = KeybindLib.KEY_INFO_TABLE[key]
  if not down and key_info and key_info.category ~= "mod" then
    local mod_mask = KeybindLib:GetModifiersMaskNow()
    local input_mask = bit.bor(mod_mask, key)

    keychord_capture_callback(input_mask)
    keychord_capture_callback = nil
  end
end)

TheInput:AddMouseButtonHandler(function(button, down, x, y)
  if not down then
    HandleKeyTrigger(button)
  end

  if not keychord_capture_callback then return end
  if not down then
    local mod_mask = KeybindLib:GetModifiersMaskNow()
    local input_mask = bit.bor(mod_mask, button)

    keychord_capture_callback(input_mask)
    keychord_capture_callback = nil
  end
end)



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
