-- Developed by rtk0c on GitHub and others
-- https://github.com/rtk0c/dont-starve-mods/tree/master/KeybindMagic
--
-- It is not required, however very nice, to indicate so if you redistribute a
-- copy of this software if it contains changes not a part of the above source.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software to use, copy, modify, merge, publish, distribute without
-- limitation, subject to the following conditions:
-- 
-- The above permission and source notice shall be included in all copies or
-- substantial portions of the Software.

local G = GLOBAL
local rawget = G.rawget

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local PopupDialog = require "screens/redux/popupdialog"
local OptionsScreen = require "screens/redux/optionsscreen"
local TEMPLATES = require "widgets/redux/templates"

-- Generate reverse lookup table from the one declared in modinfo.lua for config options
local keycode2key = { [0] = "KEY_DISABLED" }
for _, key_option in pairs(modinfo.keys) do
  local varname = key_option.data
  if varname ~= "KEY_DISABLED" then
    keycode2key[rawget(G, varname)] = varname
  end
end



-----------------------------
-- Helpers and exported stuff

KEYBIND_MAGIC = {}

local function StringifyKeycode(keycode)
  return keycode2key[keycode]
end
KEYBIND_MAGIC.StringifyKeycode = StringifyKeycode

local function ParseKeyString(key)
  return key == "KEY_DISABLED" and 0 or rawget(G, key)
end
KEYBIND_MAGIC.ParseKeyString = ParseKeyString

local function LocalizeKeyString(key)
  -- If key is unset, return the string for "- No Bind -"
  if key == 0 then return G.STRINGS.UI.CONTROLSSCREEN.INPUTS[9][2] end
  return G.STRINGS.UI.CONTROLSSCREEN.INPUTS[1][key]
end
KEYBIND_MAGIC.LocalizeKeyString = LocalizeKeyString


local KeybindSetter = Class(Widget, function(self, width, height, text_size)
  Widget._ctor(self, modname .. ":KeybindSetter")
  local spacing = 15

  -- Fields:
  -- These must be set separately after newing
  -- This is done because in the ModConfigurationScreen inject, we only get access to the config value after replacing widgets, so they can't be constructor arguments

  self.initial_key = 0
  self.default_key = 0
  self.on_rebind = function() end
  
  local changed_image = self:AddChild(Image("images/global_redux.xml", "wardrobe_spinner_bg.tex"))
  self.changed_image = changed_image
  changed_image:SetTint(1, 1, 1, 0.3) -- screens/redux/optionsscreen.lua: BuildControlGroup()
  changed_image:ScaleToSize(width, height)
  changed_image:Hide()

  local binding_btn = self:AddChild(ImageButton("images/global_redux.xml", "blank.tex", "spinner_focus.tex"))
  self.binding_btn = binding_btn
  binding_btn:ForceImageSize(width, height)
  binding_btn:SetTextColour(G.UICOLOURS.GOLD_CLICKABLE)
  binding_btn:SetTextFocusColour(G.UICOLOURS.GOLD_FOCUS)
  binding_btn:SetFont(G.CHATFONT)
  binding_btn:SetText(LocalizeKeyString(initial_key))
  binding_btn:SetTextSize(text_size)
  binding_btn:SetOnClick(function() self:PopupKeyBindDialog() end)

  local unbinding_btn = self:AddChild(ImageButton("images/global_redux.xml", "close.tex", "close.tex"))
  self.unbinding_btn = unbinding_btn
  unbinding_btn:SetPosition(width/2 + spacing - 5, 0)
  unbinding_btn:SetScale(0.4, 0.4)
  unbinding_btn:SetHoverText(G.STRINGS.UI.CONTROLSSCREEN.UNBIND)
  unbinding_btn:SetOnClick(function() self:RebindTo(0) end)

  self.focus_forward = binding_btn
end)

function KeybindSetter:RebindTo(new_key)
  self.binding_btn:SetText(LocalizeKeyString(new_key))
  self.on_rebind(new_key)
  if new_key == self.initial_key then
    self.changed_image:Hide()
  else
    self.changed_image:Show()
  end
end

function KeybindSetter:RevertChanges()
  self:RebindTo(self.initial_key)
end

function KeybindSetter:PopupKeyBindDialog()
  local body_text = G.STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT
    .. '\n\n'
    .. string.format(G.STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT, LocalizeKeyString(self.default_key))

  local dialog = PopupDialog(self.title, body_text, {
    {
      text = G.STRINGS.UI.CONTROLSSCREEN.CANCEL,
      cb = function()
        TheFrontEnd:PopScreen()
      end,
    },
  })
  dialog.OnRawKey = function(_, key, down)
    if down or not keycode2key[key] then return end -- wait for releasing valid key
    self:RebindTo(key)
    TheFrontEnd:PopScreen()
    TheFrontEnd:GetSound():PlaySound('dontstarve/HUD/click_move')
  end

  TheFrontEnd:PushScreen(dialog)
end


------------------------
-- OptionsScreen injects

-- There will ever be max of 1 instance of OptionsScreen, global variable is fine
-- Making this a field is much more work to avoid conflicts between mods
local _pending_changes = {}

-- @tparam OptionsScreen opt_screen The OptionsScreen instance that this keybind entry is to be a child to.
-- @tparam table config_option The entry from modinfo.configuration_options corresponding to this keybind entry.
local function MakeKeybindControlEntry(opt_screen, config_option)
  local x = -371 -- x coord of the left edge
  local button_width = 250
  local button_height = 48
  local label_width = 375
  local spacing = 15

  -- "kw" for "Keybind Widget"
  -- This is a reminiscient from the KeybindLib code, but "ke" is a much less unique combination, we keep it
  local kw = Widget(modname .. ":KeybindEntry")
  kw.bg = kw:AddChild(TEMPLATES.ListItemBackground(700, button_height))
  kw.bg:SetPosition(-60, 0)
  kw.bg:SetScale(1.025, 1)
  kw:SetScale(1,1,0.75)

  local label = kw:AddChild(Text(G.CHATFONT, 28))
  kw.label = label
  label:SetString(config_option.label)
  label:SetHAlign(G.ANCHOR_LEFT)
  label:SetColour(G.UICOLOURS.GOLD_UNIMPORTANT)
  label:SetRegionSize(label_width, 50)
  x = x + label_width/2
  label:SetPosition(x, 0)
  label:SetClickable(false)

  local keybind_setter = kw:AddChild(KeybindSetter(button_width, button_height, 30))
  kw.keybind_setter = keybind_setter
  local curr_key = ParseKeyString(GetModConfigData(config_option.name))
  keybind_setter.default_key = ParseKeyString(config_option.default)
  keybind_setter.initial_key = curr_key
  keybind_setter:RebindTo(curr_key)
  keybind_setter.on_rebind = function(new_key)
    if kw.keybind_setter.initial_key == new_key then
      _pending_changes[kw] = nil
    else
      _pending_changes[kw] = new_key
      if not opt_screen:IsDirty() then
        opt_screen:MakeDirty()
      end
    end
  end
  x = x + label_width/2 + spacing + button_width/2
  keybind_setter:SetPosition(x, 0)

  -- OptionsScreen:RefreshControls() assumes the existence of these, add them to make it not crash
  kw.controlId = 0
  kw.control = {}
  kw.changed_image = keybind_setter.changed_image

  kw.keybind_name = config_option.name

  kw.focus_forward = kw.keybind_setter

  return kw
end

local old_OptionsScreen_Save = OptionsScreen.Save
function OptionsScreen:Save(cb)
  -- Generate a keybind name -> config option index lookup table
  local keybind_name2idx = {}
  for i, conf_opt in ipairs(modinfo.configuration_options) do
    if conf_opt.is_keybind then
      keybind_name2idx[conf_opt.name] = i
    end
  end

  local config = G.KnownModIndex:LoadModConfigurationOptions(modname, true)
  for kw, new_key in pairs(_pending_changes) do
    local name = kw.keybind_name

    -- Notify the mod of a keybind change
    KEYBIND_MAGIC.on_keybind_changed(name, new_key)
    -- Note we don't pass in `config` here, because
    -- KnownModIndex maintains an internal reference to the current mod configuration table, which is returned by LoadModConfigurationOptions()
    -- (same as `config`)
    G.KnownModIndex:SetConfigurationOption(modname, name, StringifyKeycode(new_key))
  end
  _pending_changes = {}
  G.KnownModIndex:SaveConfigurationOptions(function() end, modname, config, modinfo.client_only_mod)

  return old_OptionsScreen_Save(self, cb)
end

local old_OptionsScreen_RevertChanges = OptionsScreen.RevertChanges
function OptionsScreen:RevertChanges()
  for kw, _ in pairs(_pending_changes) do
    kw.keybind_setter:RevertChanges()
  end
  _pending_changes = {}

  return old_OptionsScreen_RevertChanges(self)
end

AddClassPostConstruct("screens/redux/optionsscreen", function(self)
  -- Reusing the same list is fine, per the current logic in ScrollableList:SetList()
  -- Don't call ScrollableList:AddItem() one by one to avoid wasting time recalcuating the list size
  local clist = self.kb_controllist
  local items = clist.items

  local section_title = Text(G.HEADERFONT, 30, modname)
  section_title:SetHAlign(G.ANCHOR_MIDDLE)
  section_title:SetColour(G.UICOLOURS.GOLD_SELECTED)
  -- OptionsScreen:RefreshControls() assumes the existence of these, add them to make it not crash
  section_title.controlId = 0
  section_title.control = {}
  section_title.changed_image = { Show = function() end, Hide = function() end }
  table.insert(items, clist:AddChild(section_title))

  for i, conf_opt in ipairs(modinfo.configuration_options) do
    if conf_opt.is_keybind then
      table.insert(items, clist:AddChild(MakeKeybindControlEntry(self, conf_opt)))
    end
  end

  clist:SetList(items, true)
end)


---------------------------------
-- ModConfigurationScreen injects
-- This seciton is adapted from https://github.com/liolok/RangeIndicator/blob/master/keybind.lua

-- Repalce config options's Spinner with a KeybindButton like the one from OptionsScreen
AddClassPostConstruct('screens/redux/modconfigurationscreen', function(self)
  if self.modname ~= modname then return end -- avoid messing up other mods

  -- Subtracted 25 from the original 225 to fit our unbinding button on the right side
  local button_width = 200 -- screens/redux/modconfigurationscreen.lua: spinner_width
  local button_height = 40 -- screens/redux/modconfigurationscreen.lua: item_height
  local text_size = 25 -- screens/redux/modconfigurationscreen.lua: same as LabelSpinner's default
  local widget_name = modname .. ":KeybindButton" -- avoid being messed up by other mods

  for _, widget in ipairs(self.options_scroll_list.widgets_to_update) do
    -- "ks" for "Keybind Setter"
    local ks = KeybindSetter(button_width, button_height, text_size)
    ks.on_rebind = function(new_key)
      local new_key_str = StringifyKeycode(new_key)
      if new_key_str ~= widget.opt.data.initial_value then self:MakeDirty() end
      self.options[widget.real_index].value = new_key_str
      widget.opt.data.selected_value = new_key_str
      widget:ApplyDescription()
    end
    ks:Hide()
    ks:SetPosition(widget.opt.spinner:GetPosition()) -- take original spinner's place

    widget.opt[widget_name] = widget.opt:AddChild(ks)
    widget.opt.focus_forward = function() return ks.shown and ks or widget.opt.spinner end
  end

  local OldApplyDataToWidget = self.options_scroll_list.update_fn
  self.options_scroll_list.update_fn = function(context, widget, data, ...)
    local result = OldApplyDataToWidget(context, widget, data, ...)
    local ks = widget.opt[widget_name]
    if not (ks and data and not data.is_header) then return result end

    for _, v in ipairs(self.config) do
      if v.name == data.option.name then
        -- Skip our logic if this config option is not a keybind
        if not v.is_keybind then return result end

        ks.default_key = ParseKeyString(v.default)
        ks.initial_key = ParseKeyString(data.initial_value)
        ks:RebindTo(ParseKeyString(data.selected_value))

        widget.opt.spinner:Hide()
        ks:Show()

        return result
      end
    end
  end

  self.options_scroll_list:RefreshView()
end)
