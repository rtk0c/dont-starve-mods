---- FOR DEBUG ----
local inspect = require "inspect"
---- END ----

local class_def = kleiloadlua("scripts/screens/redux/optionsscreen.lua")

-- The plan: we need to extract the `all_controls` local variable from the chunk `class_def` with debug.getlocal()
-- To do that, we need to somehow inject a callback that gets called somewhere after `all_controls` is defined.
-- By inspection, the OptionsScreen class is created at the very end of all local variables with a call to the global function `Class()`,
-- so we set our own env that intercepts lookups for a global named "Class" and return a wrapper that extracts `all_controls`, and then forwards execution to the actual `Class()` function

local class_all_controls = nil

local env = {}
local env_metatable = {
  __index = function(t, key)
    -- Intercept the first time Class() is looked up
    -- If we already got class_all_controls, no need to intercept anymore, just give them the default thing
    if key == "Class" and class_all_controls == nil then
      return function(...)
        local idx = 1
        while true do
          local name, value = debug.getlocal(2, idx)
          if not name then break end
          if name == "all_controls" then
            class_all_controls = value
            break
          end
          idx = idx + 1
        end
        return _G.Class(...)
      end
    end

    -- If not something we're intercepting, forward to the global environment
    return _G[key]
  end,

  __newindex = function(t, key, value)
    _G[key] = value
  end
}

setmetatable(env, env_metatable)
setfenv(class_def, env)
local OptionsScreen = class_def()
-- Feed this to the package cache, as-if somebody had called require()
package.loaded["screens/redux/optionsscreen"] = OptionsScreen

-- Now here is a problem: how tf do we _add_ things to the controls menu?
-- This is roughly how the vanilla logic works:
-- + Each control appearing in the list has a unique integer ID, e.g. Primary is 0, Secondary is 1
-- + According to strings.lua, these ID are matched in DontStarveInputHandler.h in the native code, which we obviously don't have access to
-- + They are also translated with the gettext system (the strings.lua has an array of English names, the indices of which need to matches the IDs)
-- This means we can't possibly add anything using _the vanilla way_ without massive, massive surgeries, including
-- + Invent an ID generator (an incrementing counter is find)
-- + Hijack the gettext i18n system to allow mods to inject new entries in there
--   + This would be good in general for mods to have, so we can stop writing the shitting `if use_chinese then "这个" else "this" end`
--   + Obviously, we can't run .po files through the compiler & hijack gettext itself (which is in the native parts), so some efforts needs to be made to hijack the lua UI code that loads l10n from gettext
-- + Hijack the input system so that it will spit out control codes based on the keybind
-- This just seems like a lot of work.
--
-- Is there a better way? Maybe? I can only think of one thing:
-- Merely use OptionsScreen for configuration, but for mods' keybinds, we insert our own Widget that forwards the keybinds into a table,
-- and then have a shared KeyDown handler that matches from the table, and dispatches control events (a custom one based on callbacks probably, because using numeric IDs + a big switch really sucks) to the registered keybind handlers.
-- That's also a lot of work, but at least we don't have to figure out how gettext works.
--
-- Here ends the diary.

-- Another problem: the control mapping process (the user press a keychord -> store) process is done entirely in TheInputProxy, which is native
-- Functions like OptionsScreen:OnControlMapped and OptionsScreen:MapControl are just UI hooks
-- We don't need to add controls to the native system. We just need to hijack the keychord capturing logic, which means hijacking some control (e.g. 0, i.e. Primary) for the keychord capture to start, but display text for our own keybind, and then get the result from TheInputProxy (from the callback added by TheInput:AddControlMappingHandler), and then reset Priamry to its original control

-- TODO figure out how does inputId works, it seems like a 32-bit integer, presumably there're some flag bits in there for modifieres?

-- Using: CONTROL_PRIMARY for hijacking keychord capture
local is_hijacking_capture = false

-- Notes on Terminology:
-- Vanilla uses "control" for an action (e.g. Primary, left click by default), we use "keybind"
-- Vanilla uses "control" for a keychord, we use "keychord"

-- Notes on Control Flow:
-- The UI widgets are all built in OptionsScreen's ctor call.
-- The part we care about, the controls tab, is built in OptionsScreen:_BuildControls().
-- In there, iterate `all_controls` and generate the widgets and callbacks corresponding to each array element.
-- There are branches for keyboard keybinds and controller keybinds, we only care about the keyboard case. 

kbd_list = {}

local kbd_metatable = {
  __index = function(t, k)
    if k == "name" then return t._name end
    return nil
  end,

  __newindex = function(t, k, v)
    if k == "name" then
      t._name = v
      STRINGS.UI.CONTROLSSCREEN.CONTROLS[t.string_idx] = v
    else
      rawset(t, k, v)
    end
  end,
}

-------
-- @param id An unique identifier for this keybind.
-- @param name A human-readable (and preferrably localized) name for this keybind. For dispaly in UI.
-- @param callback Function to be called when the keybind is triggered.
function RegisterKeybind(id, name, callback)
  local string_idx = #STRINGS.UI.CONTROLSSCREEN.CONTROLS + 1

  local kbd = setmetatable(
    {id = id, string_idx = string_idx, input_mask = 0xFFFFFFFF},
    kbd_metatable)

  -- Populate these field with the setter; see definition of `kbd_metatable`
  kbd.name = name

  -- Vanilla reuses the C++ control ID as `name`, except this is 0-indexed, so they +1 for every access into the strings array.
  -- We have 1-indexed already, -1 to match their code.
  table.insert(class_all_controls, {name = string_idx-1, keyboard = CONTROL_PRIMARY})
  table.insert(kbd_list, kbd)
end

RegisterKeybind("test_kbd", "Test Keybind", function() print("keybind pressed!") end)

local old_MapControl = OptionsScreen.MapControl

function OptionsScreen:MapControl(device_id, control_id)
  if is_hijacking_capture and control_id == CONTROL_PRIMARY then
    -- TODO
  end
  return old_MapControl(self, device_id, control_id)
end

local old_OnControlMapped = OptionsScreen.OnControlMapped

function OptionsScreen:OnControlMapped(device_id, control_id, input_id, has_changed)
  if is_hijacking_capture and control_id == CONTROL_PRIMARY then
    -- TODO
  end
  return old_OnControlMapped(self, device_id, control_id, input_id, has_changed)
end
