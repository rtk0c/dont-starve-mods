-- Experiment: 
-- - yes that path does refer to the OptionsScreen package
-- - when our mod loads on game startup, the UI is not loaded yet, so this is nil
-- - c_reset() same thing
-- - therefore, most likely during server joins and shard hops it's also the same
-- print("MOD HERE BLAHB BALH"..tostring(package.loaded["screens/redux/optionsscreen"]))

local inspect = require "inspect"

-- print(OptionsScreen)
-- print(kleiloadlua("scripts/screens/redux/optionsscreen.lua"))

local class_def = kleiloadlua("scripts/screens/redux/optionsscreen.lua")

-- The plan: we need to extract the `all_controls` local variable from the chunk `class_def` with debug.getlocal()
-- To do that, we need to somehow inject a callback that gets called somewhere after `all_controls` is defined.
-- By inspection, the OptionsScreen class is created at the very end of all local variables with a call to the global function `Class()`,
-- so we set our own env that intercepts lookups for a global named "Class" and return a wrapper that extracts `all_controls`, and then forwards execution to the actual `Class()` function

local class_all_controls = nil

local env = {}
local env_metatable = {
	__index = function(self, key)
		if key == "Class" then
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

	__newindex = function(self, key, value)
		_G[key] = value
	end
}
setmetatable(env, env_metatable)

-- I think we can safely assume vanilla's code is valid, otherwise the first time won't even load
--[[
if type(class_def) ~= "function" then
	print("ERROR: got " .. tostring(class_def) .. " for the class def, expected function")
	return
end
--]]

setfenv(class_def, env)
package.loaded["screens/redux/optionsscreen"] = class_def()

-- This successfully removes the first entry, the one for Priamry
table.remove(class_all_controls, 1)
-- print(inspect(class_all_controls, 2))

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
