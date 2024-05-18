kbd_list = {}

-------
-- @param kbd The keybind object.
-- @param kbd.id An unique identifier for this keybind.
-- @param kbd.name A human-readable (and preferrably localized) name for this keybind. For dispaly in UI.
-- @param kbd.callback Function to be called when the keybind is triggered.
function RegisterKeybind(kbd)
  kbd.input_mask = 0 -- Mask for unset keybind
  GLOBAL.table.insert(kbd_list, kbd)
end

RegisterKeybind({
  id = "test_kbd",
  name = "Test Keybind",
  callback = function() print("keybind pressed!") end,
})

key_infos = {
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

  local key_info = key_infos[keycode]
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
