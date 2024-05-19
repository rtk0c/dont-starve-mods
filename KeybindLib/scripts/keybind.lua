-- NOTE: this file runs with GLOBAL environment

----- Notes on Terminology -----
-- Vanilla uses "control" for an action (e.g. Primary, left click by default), we use "keybind".
-- Vanilla uses "control" for a key combination, we use "keychord" for the semantics of this. The encoded representations is "input mask".
-- "input mask" is an uint32 that matches a specific keychord.
-- "mod[ifiers] mask" is the upper 16 bits of an input mask, that describes the modifier states.
-- "keycode" is the lower 16 bits of an input mask, that describes the non-modifier key. Matches vanilla's KEY_xxx in constants.lua
-- "key" is any on/off stateful input, so it can be keyboard keys or mouse buttons or controller buttons



KeybindLib = {}

KeybindLib.keybind_registry = {}
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

-------
-- @param keybind The keybind object.
-- @param keybind.id An unique identifier for this keybind.
-- @param keybind.modid An unique identifier for the mod that is registering this keybind. If your modinfo.lua uses the de-facto "id" field, this should have the same value; your mod's name will be automatically looked up and used for display. If not, this will be dispalyed directly.
-- @param keybind.name A human-readable (and preferrably localized) name for this keybind. For dispaly in UI.
-- @param keybind.callback Function to be called when the keybind is triggered.
function KeybindLib:RegisterKeybind(keybind)
  local reg = KeybindLib.keybind_registry

  if reg[keybind.id] then
    error("A keybind with ID '" .. keybind.id .. "' already exists.")
  end

  setmetatable(keybind, keybind_metatable)
  keybind._input_mask = 0 -- Mask for unset keybind
  keybind.index = #reg + 1

  -- Register for id -> keybind lookup
  reg[keybind.modid .. ":" .. keybind.id] = keybind
  -- Register for ordered iteration
  reg[keybind.index] = keybind
end

-------
-- @param modid Mod's ID which they keybind came from.
-- @param id The keybind's ID to be unregistered.
function KeybindLib:UnregisterKeybind(modid, id)
  local reg = KeybindLib.keybind_registry
  local keybind = reg[modid .. ":" .. id]
  if keybind then
    reg[id] = nil
    reg[keybind.index] = nil
  end
end



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
  [MOUSEBUTTON_SCROLLUP] = { name = "Mouse Scroll Up", category = "mouse" },
  [MOUSEBUTTON_SCROLLDOWN] = { name = "Mouse Scroll Down", category = "mouse" },
}



local MOD_LCTRL_BIT = 31
local MOD_LSHIFT_BIT = 30
local MOD_LALT_BIT = 29
local MOD_LSUPER_BIT = 28
local MOD_RCTRL_BIT = 27
local MOD_RSHIFT_BIT = 26
local MOD_RALT_BIT = 25
local MOD_RSUPER_BIT = 24

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

local function StringConcat(separator, ...)
  local res = ""
  for _, v in ipairs(arg) do
    if v then
      res = res .. tostring(v) .. separator
    end
  end
  return res
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

  for keycode, key_info in pairs(KeybindLib.KEY_INFO_TABLE) do
    if key_info.name == key_name then
      input_mask = bit.bor(input_mask, keycode)
      break
    end
  end

  return input_mask
end

function KeybindLib:InputMaskToString(v)
  local keycode = bit.band(bit.rshift(v, 32), 0xFFFF)
  if keycode == 0 then
    return ""
  end

  local key_info = KeybindLib.KEY_INFO_TABLE[keycode]
  local primary_key_name = key_info and key_info.name or "<unknown>"

  return StringConcat(" + ",
    TestBit(v, MOD_LCTRL_BIT) and "LCtrl",
    TestBit(v, MOD_LSHIFT_BIT) and "LShift",
    TestBit(v, MOD_LALT_BIT) and "LAlt",
    TestBit(v, MOD_LSUPER_BIT) and "LSuper",
    TestBit(v, MOD_RCTRL_BIT) and "RCtrl",
    TestBit(v, MOD_RSHIFT_BIT) and "RShift",
    TestBit(v, MOD_RALT_BIT) and "RAlt",
    TestBit(v, MOD_RSUPER_BIT) and "RSuper") .. primary_key_name
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



local last_load_failed = false

function KeybindLib:LoadKeybindMappings()
  local path = KnownModIndex:GetModConfigurationPath() .. "KeybindLib_Mappings"
  TheSim:GetPersistentString(path, function(load_success, str)
    if not load_success then
      last_load_failed = true
      print("[KeybindLib] Failed to load mod keybinds. You will get default keybinds, and any changes will not be saved.")
      return
    end

    local cursor = 1
    repeat
      local assign_idx = string.find(str, "=", cursor, true)
      local key = string.sub(str, cursor, assign_idx-1) -- <modid>:<id>
      cursor = assign_idx + 1

      local newline_idx = string.find(str, "\n", cursor, true)
      local input_mask_str
      if newline_idx then
        input_mask_str = string.sub(str, cursor, newline_idx-1)
        cursor = newline_idx + 1
      else
        input_mask_str = string.sub(str, cursor)
        cursor = nil
      end

      local keybind = KeybindLib.keybind_registry[key]
      if keybind then
        keybind:SetInputMask(KeybindLib:InputMaskFromString(input_mask_str))
      end
    until not cursor
  end)
end

function KeybindLib:SaveKeybindMappings(override_safety)
  -- If last load failed, let's not override the user's (probably still fine on disk) keybinds with the default values
  -- unless the caller specifically asked us to.
  if last_load_failed and not override_safety then
    return
  end

  local saved_kbd = {}
  for _, kbd in ipairs(KeybindLib.keybind_registry) do
    table.insert(saved_kbd, kbd.modid .. ":" .. kbd.id .. "=" .. KeybindLib:InputMaskToString(kbd:GetInputMask()))
  end

  local path = KnownModIndex:GetModConfigurationPath() .. "KeybindLib_Mappings"
  TheSim:SetPersistentString(path, table.concat(saved_kbd, "\n"), false)
end
