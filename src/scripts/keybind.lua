----- Notes on Terminology -----
-- Vanilla uses "control" for an action (e.g. Primary, left click by default), we use "keybind".
-- Vanilla uses "control" for a key combination, we use "keychord" for the semantics of this. The encoded representations is "input mask".
-- "input mask" is an uint32 that matches a specific keychord.
-- "mod[ifiers] mask" is the upper 16 bits of an input mask, that describes the modifier states.
-- "keycode" is the lower 16 bits of an input mask, that describes the non-modifier key. Matches vanilla's KEY_xxx in constants.lua
-- "key" is any on/off stateful input, so it can be keyboard keys or mouse buttons or controller buttons



keybind_registry = {}
keycode_to_keybinds = {}

local keybind_methods = {
  GetInputMask = function(self)
    return self._input_mask
  end,
  SetInputMask = function(self, v)
    local bit = GLOBAL.bit
    local old_keycode = bit.band(bit.rshift(self._input_mask, 32), 0xFFFF)
    self._input_mask = v
    local new_keycode = bit.band(bit.rshift(v, 32), 0xFFFF)

    local old_hooks = keycode_to_keybinds[old_keycode]
    if old_hooks then
      old_hooks[self] = nil
    end

    if new_keycode ~= 0 then
      local new_hooks = keycode_to_keybinds[new_keycode]
      if not new_hooks then
        new_hooks = {}
        keycode_to_keybinds[new_keycode] = new_hooks
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
function RegisterKeybind(keybind)
  if keybind_registry[keybind.id] then
    error("A keybind with ID '" .. keybind.id .. "' already exists.")
  end

  GLOBAL.setmetatable(keybind, keybind_metatable)
  keybind._input_mask = 0 -- Mask for unset keybind
  keybind.index = #keybind_registry + 1

  -- Register for id -> keybind lookup
  keybind_registry[keybind.id] = keybind
  -- Register for ordered iteration
  keybind_registry[keybind.index] = keybind
end

-------
-- @param id The keybind's ID to be unregistered.
function UnregisterKeybind(id)
  local keybind = keybind_registry[id]
  if keybind then
    keybind_registry[id] = nil
    keybind_registry[keybind.index] = nil
  end
end

-------
-- Maps keycode into a key information table. Not all possible keycodes emitted by C++ code are stored
-- here, so always check against nil lookup values.
KEY_INFO_TABLE = {
  [GLOBAL.KEY_KP_0] = { name = "Numpad 0", category = "numpad" },
  [GLOBAL.KEY_KP_1] = { name = "Numpad 1", category = "numpad" },
  [GLOBAL.KEY_KP_2] = { name = "Numpad 2", category = "numpad" },
  [GLOBAL.KEY_KP_3] = { name = "Numpad 3", category = "numpad" },
  [GLOBAL.KEY_KP_4] = { name = "Numpad 4", category = "numpad" },
  [GLOBAL.KEY_KP_5] = { name = "Numpad 5", category = "numpad" },
  [GLOBAL.KEY_KP_6] = { name = "Numpad 6", category = "numpad" },
  [GLOBAL.KEY_KP_7] = { name = "Numpad 7", category = "numpad" },
  [GLOBAL.KEY_KP_8] = { name = "Numpad 8", category = "numpad" },
  [GLOBAL.KEY_KP_9] = { name = "Numpad 9", category = "numpad" },
  [GLOBAL.KEY_KP_PERIOD] = { name = "Numpad .", category = "numpad" },
  [GLOBAL.KEY_KP_DIVIDE] = { name = "Numpad /", category = "numpad" },
  [GLOBAL.KEY_KP_MULTIPLY] = { name = "Numpad *", category = "numpad" },
  [GLOBAL.KEY_KP_MINUS] = { name = "Numpad -", category = "numpad" },
  [GLOBAL.KEY_KP_PLUS] = { name = "Numpad +", category = "numpad" },
  [GLOBAL.KEY_KP_ENTER] = { name = "Numpad Enter", category = "numpad" },
  [GLOBAL.KEY_KP_EQUALS] = { name = "Numpad =", category = "numpad" },

  -- Misc category
  [GLOBAL.KEY_MINUS] = { name = "-" },
  [GLOBAL.KEY_EQUALS] = { name = "=" },
  [GLOBAL.KEY_BACKSPACE] = { name = "Backspace" },
  [GLOBAL.KEY_SPACE] = { name = "Space" },
  [GLOBAL.KEY_ENTER] = { name = "Enter" },
  [GLOBAL.KEY_ESCAPE] = { name = "Esc" },
  [GLOBAL.KEY_TAB] = { name = "Tab" },
  [GLOBAL.KEY_HOME] = { name = "Home" },
  [GLOBAL.KEY_INSERT] = { name = "Ins" },
  [GLOBAL.KEY_DELETE] = { name = "Del" },
  [GLOBAL.KEY_END] = { name = "End" },
  [GLOBAL.KEY_PAGEUP] = { name = "PgUp" },
  [GLOBAL.KEY_PAGEDOWN] = { name = "PgDn" },
  [GLOBAL.KEY_PAUSE] = { name = "Pause" },
  [GLOBAL.KEY_PRINT] = { name = "Print" },

  [GLOBAL.KEY_CAPSLOCK] = { name = "CapsLock", category = "mod" },
  [GLOBAL.KEY_SCROLLOCK] = { name = "ScrollLock", category = "mod" },
  [GLOBAL.KEY_RSHIFT]  = { name = "RShift", category = "mod" },
  [GLOBAL.KEY_LSHIFT]  = { name = "LShift", category = "mod" },
  [GLOBAL.KEY_RCTRL]  = { name = "RCtrl", category = "mod" },
  [GLOBAL.KEY_LCTRL]  = { name = "LCtrl", category = "mod" },
  [GLOBAL.KEY_RALT]  = { name = "RAlt", category = "mod" },
  [GLOBAL.KEY_LALT]  = { name = "LAlt", category = "mod" },
  [GLOBAL.KEY_LSUPER] = { name = "LSuper", category = "mod" },
  [GLOBAL.KEY_RSUPER] = { name = "RSuper", category = "mod" },
  -- These seems to be amalganation of the left/right keys done in the C++ later
  --[[
  [GLOBAL.KEY_ALT] = { name = "Alt", category = "mod" },
  [GLOBAL.KEY_CTRL] = { name = "Ctrl", category = "mod" },
  [GLOBAL.KEY_SHIFT] = { name = "Shift", category = "mod" },
  --]]

  [GLOBAL.KEY_PERIOD] = { name = "." },
  [GLOBAL.KEY_SLASH] = { name = "/" },
  [GLOBAL.KEY_SEMICOLON] = { name = ";" },
  [GLOBAL.KEY_LEFTBRACKET] = { name = "[" },
  [GLOBAL.KEY_BACKSLASH] = { name = "\\" },
  [GLOBAL.KEY_RIGHTBRACKET] = { name = "]" },
  [GLOBAL.KEY_TILDE] = { name = "`" },
  [GLOBAL.KEY_A] = { name = "A", category = "letter" },
  [GLOBAL.KEY_B] = { name = "B", category = "letter" },
  [GLOBAL.KEY_C] = { name = "C", category = "letter" },
  [GLOBAL.KEY_D] = { name = "D", category = "letter" },
  [GLOBAL.KEY_E] = { name = "E", category = "letter" },
  [GLOBAL.KEY_F] = { name = "F", category = "letter" },
  [GLOBAL.KEY_G] = { name = "G", category = "letter" },
  [GLOBAL.KEY_H] = { name = "H", category = "letter" },
  [GLOBAL.KEY_I] = { name = "I", category = "letter" },
  [GLOBAL.KEY_J] = { name = "J", category = "letter" },
  [GLOBAL.KEY_K] = { name = "K", category = "letter" },
  [GLOBAL.KEY_L] = { name = "L", category = "letter" },
  [GLOBAL.KEY_M] = { name = "M", category = "letter" },
  [GLOBAL.KEY_N] = { name = "N", category = "letter" },
  [GLOBAL.KEY_O] = { name = "O", category = "letter" },
  [GLOBAL.KEY_P] = { name = "P", category = "letter" },
  [GLOBAL.KEY_Q] = { name = "Q", category = "letter" },
  [GLOBAL.KEY_R] = { name = "R", category = "letter" },
  [GLOBAL.KEY_S] = { name = "S", category = "letter" },
  [GLOBAL.KEY_T] = { name = "T", category = "letter" },
  [GLOBAL.KEY_U] = { name = "U", category = "letter" },
  [GLOBAL.KEY_V] = { name = "V", category = "letter" },
  [GLOBAL.KEY_W] = { name = "W", category = "letter" },
  [GLOBAL.KEY_X] = { name = "X", category = "letter" },
  [GLOBAL.KEY_Y] = { name = "Y", category = "letter" },
  [GLOBAL.KEY_Z] = { name = "Z", category = "letter" },
  [GLOBAL.KEY_F1] = { name = "F1", category = "fn" },
  [GLOBAL.KEY_F2] = { name = "F2", category = "fn" },
  [GLOBAL.KEY_F3] = { name = "F3", category = "fn" },
  [GLOBAL.KEY_F4] = { name = "F4", category = "fn" },
  [GLOBAL.KEY_F5] = { name = "F5", category = "fn" },
  [GLOBAL.KEY_F6] = { name = "F6", category = "fn" },
  [GLOBAL.KEY_F7] = { name = "F7", category = "fn" },
  [GLOBAL.KEY_F8] = { name = "F8", category = "fn" },
  [GLOBAL.KEY_F9] = { name = "F9", category = "fn" },
  [GLOBAL.KEY_F10] = { name = "F10", category = "fn" },
  [GLOBAL.KEY_F11] = { name = "F11", category = "fn" },
  [GLOBAL.KEY_F12] = { name = "F12", category = "fn" },

  [GLOBAL.KEY_UP] = { name = "Up", category = "arrow" },
  [GLOBAL.KEY_DOWN] = { name = "Down", category = "arrow" },
  [GLOBAL.KEY_RIGHT] = { name = "Right", category = "arrow" },
  [GLOBAL.KEY_LEFT] = { name = "Left", category = "arrow" },

  [GLOBAL.KEY_0] = { name = "0", category = "number" },
  [GLOBAL.KEY_1] = { name = "1", category = "number" },
  [GLOBAL.KEY_2] = { name = "2", category = "number" },
  [GLOBAL.KEY_3] = { name = "3", category = "number" },
  [GLOBAL.KEY_4] = { name = "4", category = "number" },
  [GLOBAL.KEY_5] = { name = "5", category = "number" },
  [GLOBAL.KEY_6] = { name = "6", category = "number" },
  [GLOBAL.KEY_7] = { name = "7", category = "number" },
  [GLOBAL.KEY_8] = { name = "8", category = "number" },
  [GLOBAL.KEY_9] = { name = "9", category = "number" },

  [GLOBAL.MOUSEBUTTON_LEFT] = { name = "Mouse Left", category = "mouse" },
  [GLOBAL.MOUSEBUTTON_RIGHT] = { name = "Mouse Right", category = "mouse" },
  [GLOBAL.MOUSEBUTTON_MIDDLE] = { name = "Mouse Middle", category = "mouse" },
  [GLOBAL.MOUSEBUTTON_SCROLLUP] = { name = "Mouse Scroll Up", category = "mouse" },
  [GLOBAL.MOUSEBUTTON_SCROLLDOWN] = { name = "Mouse Scroll Down", category = "mouse" },
}

MOD_LCTRL_BIT = 31
MOD_LSHIFT_BIT = 30
MOD_LALT_BIT = 29
MOD_LSUPER_BIT = 28
MOD_RCTRL_BIT = 27
MOD_RSHIFT_BIT = 26
MOD_RALT_BIT = 25
MOD_RSUPER_BIT = 24

function GetModifiersMaskNow()
  local TI = GLOBAL.TheInput
  local bit = GLOBAL.bit
  return bit.bor(
    TI:IsKeyDown(GLOBAL.KEY_LCTRL) and bit.lshift(1, MOD_LCTRL_BIT) or 0,
    TI:IsKeyDown(GLOBAL.KEY_LSHIFT) and bit.lshift(1, MOD_LSHIFT_BIT) or 0,
    -- FIXME LAlt and RAlt are not being detected right now
    TI:IsKeyDown(GLOBAL.KEY_LALT) and bit.lshift(1, MOD_LALT_BIT) or 0,
    TI:IsKeyDown(GLOBAL.KEY_LSUPER) and bit.lshift(1, MOD_LSUPER_BIT) or 0,
    TI:IsKeyDown(GLOBAL.KEY_RCTRL) and bit.lshift(1, MOD_RCTRL_BIT) or 0,
    TI:IsKeyDown(GLOBAL.KEY_RSHIFT) and bit.lshift(1, MOD_RSHIFT_BIT) or 0,
    TI:IsKeyDown(GLOBAL.KEY_RALT) and bit.lshift(1, MOD_RALT_BIT) or 0,
    TI:IsKeyDown(GLOBAL.KEY_RSUPER) and bit.lshift(1, MOD_RSUPER_BIT) or 0)
end

local function TestBit(mask, n)
  local bit = GLOBAL.bit
  return bit.band(bit.rshift(mask, n), 1) == 1
end

local function StringConcat(separator, ...)
  local res = ""
  for _, v in GLOBAL.ipairs(arg) do
    if v then
      res = res .. GLOBAL.tostring(v) .. separator
    end
  end
  return res
end

function InputMaskFromString(str)
  -- TODO
  return 0
end

function InputMaskToString(v)
  local bit = GLOBAL.bit
  local keycode = bit.band(bit.rshift(v, 32), 0xFFFF)
  if keycode == 0 then
    return ""
  end

  local key_info = KEY_INFO_TABLE[keycode]
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

function BeginKeychordCapture(callback)
  keychord_capture_callback = callback
end

function CancelKeychordCapture()
  keychord_capture_callback = nil
end

local function HandleKeyTrigger(keycode)
  local keybind_list = keycode_to_keybinds[keycode]
  if not keybind_list then return end

  local mod_mask = GetModifiersMaskNow()
  local input_mask = GLOBAL.bit.bor(mod_mask, keycode)

  for keybind, _ in GLOBAL.pairs(keybind_list) do
    if keybind:GetInputMask() == input_mask and keybind.callback then
      keybind.callback()
    end
  end
end

GLOBAL.TheInput:AddKeyHandler(function(key, down)
  if not down then
    HandleKeyTrigger(key)
  end

  if not keychord_capture_callback then return end

  -- NOTE: this key handler only takes keyboard inputs
  -- Keep taking input until a key release
  local key_info = KEY_INFO_TABLE[key]
  if not down and key_info and key_info.category ~= "mod" then
    local mod_mask = GetModifiersMaskNow()
    local input_mask = GLOBAL.bit.bor(mod_mask, key)

    keychord_capture_callback(input_mask)
    keychord_capture_callback = nil
  end
end)

GLOBAL.TheInput:AddMouseButtonHandler(function(button, down, x, y)
  if not down then
    HandleKeyTrigger(button)
  end

  if not keychord_capture_callback then return end
  if not down then
    local mod_mask = GetModifiersMaskNow()
    local input_mask = GLOBAL.bit.bor(mod_mask, button)

    keychord_capture_callback(input_mask)
    keychord_capture_callback = nil
  end
end)

--[[
for i = 1, 10 do
  RegisterKeybind({id="test"..i, name="Do test"..i, modid="rtk0c.DST_ClientTweaks", callback = function() print("Keybind triggered: "..i) end})
end
RegisterKeybind({id="haha", name="Haha", modid="My Amazing Mod", callback = function() print("MY AMAZING MOD!!! YEAH!!!!!!") end})
RegisterKeybind({id="beers", name="-1 beers"})
--]]
