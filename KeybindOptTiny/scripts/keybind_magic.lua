local G = GLOBAL
local rawget = G.rawget

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TEMPLATES = require "widgets/redux/templates"

local _keybinds = {}
local _pending_changes = {}

-- Generate reverse lookup table from the one declared in modinfo.lua for config options
local keycode2key = { [0] = "KEY_DISABLED" }
for _, key_option in pairs(modinfo.keys) do
  local varname = key_option.data
  if varname ~= "KEY_DISABLED" then
    keycode2key[rawget(GLOBAL, varname)] = varname
  end
end

local function StringifyKeycode(keycode)
  return keycode2key[keycode]
end
local function ParseKeyString(key)
  return key == "KEY_DISABLED" and 0 or rawget(GLOBAL, key)
end

local function LocalizeKey(key)
  -- If key is unset, return the string for "- No Bind -"
  if key == 0 then return G.STRINGS.UI.CONTROLSSCREEN.INPUTS[9][2] end
  return G.STRINGS.UI.CONTROLSSCREEN.INPUTS[1][key]
end

local function UserChangeKeybind(opt_screen, kw, new_key)
  -- Display changes on screen
  kw.binding_btn:SetText(LocalizeKey(new_key))
  if kw.kbd.key ~= new_key then
    _pending_changes[kw] = new_key
    kw.changed_image:Show()
    if not opt_screen:IsDirty() then
      opt_screen:MakeDirty()
    end
  else
    _pending_changes[kw] = nil
    kw.changed_image:Hide()
  end
end

local function MakeKeybindGroup(opt_screen, kbd)
  local button_x = -371 -- x coord of the left edge
  local button_width = 250
  local button_height = 48
  local label_width = 375
  local spacing = 15

  local kw = Widget(modinfo.name .. ":" .. kbd.label)
  kw.bg = kw:AddChild(TEMPLATES.ListItemBackground(700, button_height))
  kw.bg:SetPosition(-60,0)
  kw.bg:SetScale(1.025, 1)
  kw:SetScale(1,1,0.75)

  kw.kbd = kbd

  local x = button_x

  local label = kw:AddChild(Text(G.CHATFONT, 28))
  label:SetString(kbd.label)
  label:SetHAlign(G.ANCHOR_LEFT)
  label:SetColour(G.UICOLOURS.GOLD_UNIMPORTANT)
  label:SetRegionSize(label_width, 50)
  x = x + label_width/2
  label:SetPosition(x,0)
  x = x + label_width/2 + spacing
  label:SetClickable(false)
  kw.label = label

  x = x + button_width/2
  local changed_image = kw:AddChild(Image("images/global_redux.xml", "wardrobe_spinner_bg.tex"))
  changed_image:SetTint(1,1,1,0.3)
  changed_image:ScaleToSize(button_width, button_height)
  changed_image:SetPosition(x,0)
  changed_image:Hide()
  kw.changed_image = changed_image

  local binding_btn = kw:AddChild(ImageButton("images/global_redux.xml", "blank.tex", "spinner_focus.tex"))
  binding_btn:ForceImageSize(button_width, button_height)
  binding_btn:SetTextColour(G.UICOLOURS.GOLD_CLICKABLE)
  binding_btn:SetTextFocusColour(G.UICOLOURS.GOLD_FOCUS)
  binding_btn:SetFont(G.CHATFONT)
  binding_btn:SetTextSize(30)
  binding_btn:SetPosition(x,0)
  binding_btn:SetOnClick(function()
    local g_strs = G.STRINGS.UI.CONTROLSSCREEN
    local default_text = string.format(g_strs.DEFAULT_CONTROL_TEXT, LocalizeKey(kbd.default_key))
    local popup = PopupDialogScreen(kbd.label, g_strs.CONTROL_SELECT .. "\n\n" .. default_text, {})
    popup.dialog.body:SetPosition(0, 0)

    popup.OnControl = function(_, control, down) return true end

    popup.OnRawKey = function(_, key, down)
      if not down then
        UserChangeKeybind(opt_screen, kw, key)
        G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        G.TheFrontEnd:PopScreen()
      end
    end

    G.TheFrontEnd:PushScreen(popup)
  end)
  x = x + button_width/2 + spacing
  binding_btn:SetHelpTextMessage(G.STRINGS.UI.CONTROLSSCREEN.CHANGEBIND)
  binding_btn:SetDisabledFont(G.CHATFONT)
  binding_btn:SetText(LocalizeKey(kbd.key))
  kw.binding_btn = binding_btn

  local unbinding_btn = kw:AddChild(ImageButton("images/global_redux.xml", "close.tex", "close.tex"))
  unbinding_btn:SetOnClick(function()
    UserChangeKeybind(opt_screen, kw, 0)
  end)
  unbinding_btn:SetPosition(x - 5,0)
  unbinding_btn:SetScale(0.4, 0.4)
  unbinding_btn:SetHoverText(G.STRINGS.UI.CONTROLSSCREEN.UNBIND)
  kw.unbinding_btn = unbinding_btn

  -- OptionsScreen:RefreshControls() assumes the existence of these, add them to make it not crash
  kw.controlId = 0
  kw.control = {}

  kw.focus_forward = kw.binding_btn

  return kw
end

local OptionsScreen = require "screens/redux/optionsscreen"
local old_OptionsScreen_Save = OptionsScreen.Save
function OptionsScreen:Save(cb)
  local changed_keybinds = {}
  for kw, new_key in pairs(_pending_changes) do
    local kbd = kw.kbd

    kbd.key = new_key
    table.insert(changed_keybinds, { name = kbd.name, new_key = new_key })
  end
  _pending_changes = {}
  KEYBIND_MAGIC.on_keybinds_changed(changed_keybinds)

  return old_OptionsScreen_Save(self, cb)
end
local old_OptionsScreen_RevertChanges = OptionsScreen.RevertChanges
function OptionsScreen:RevertChanges()
  for kw, new_key in pairs(_pending_changes) do
    UserChangeKeybind(self, kw, kw.kbd.default_key)
  end
  _pending_changes = {}

  return old_OptionsScreen_RevertChanges(self)
end

AddClassPostConstruct("screens/redux/optionsscreen", function(self)
  -- Reusing the same list is fine, per the current logic in ScrollableList:SetList()
  -- Don't call ScrollableList:AddItem() one by one to avoid wasting time recalcuating the list size
  local clist = self.kb_controllist
  local items = clist.items

  local section_title = Text(G.HEADERFONT, 30, modinfo.name)
  section_title:SetHAlign(G.ANCHOR_MIDDLE)
  section_title:SetColour(G.UICOLOURS.GOLD_SELECTED)
  -- OptionsScreen:RefreshControls() assumes the existence of these, add them to make it not crash
  section_title.controlId = 0
  section_title.control = {}
  section_title.changed_image = { Show = function() end, Hide = function() end }
  table.insert(items, clist:AddChild(section_title))

  for _, kbd in ipairs(_keybinds) do
    local kw = MakeKeybindGroup(self, kbd)
    table.insert(items, clist:AddChild(kw))
  end

  clist:SetList(items, true)
end)

KEYBIND_MAGIC = {}
KEYBIND_MAGIC.StringifyKeycode = StringifyKeycode
KEYBIND_MAGIC.ParseKeyString = ParseKeyString
function KEYBIND_MAGIC.Add(name, default_key, key)
function KEYBIND_MAGIC.Add(label, default_key, key)
  local obj = {
    label = label,
    default_key = default_key,
    key = key,
  }
  table.insert(_keybinds, obj)
  return obj
end



--------------------
-- This seciton is adapted from https://github.com/liolok/RangeIndicator/blob/master/keybind.lua

-- Yes, there are a bit of code duplicate betwen here and the OptionsScreen mods, but they're slightly different enough to not worth DRY-ing
-- (most of these "duplicates" are positioning and sizing stuff)
local KeyBindButton = Class(Widget, function(self, on_set_val_fn)
  Widget._ctor(self, 'KeyBindButton@' .. modname) -- avoid being messed up by other mods

  self.OnSetValue = on_set_val_fn
  self.valid = {} -- validated code/name of keys like 97/"KEY_A" or 306/"KEY_LCTRL"

  local button_width = 225 -- screens/redux/modconfigurationscreen.lua: spinner_width
  local button_height = 40 -- screens/redux/modconfigurationscreen.lua: item_height

  self.changed_image = self:AddChild(Image('images/global_redux.xml', 'wardrobe_spinner_bg.tex'))
  self.changed_image:SetTint(1, 1, 1, 0.3) -- screens/redux/optionsscreen.lua: BuildControlGroup()
  self.changed_image:ScaleToSize(button_width, button_height)
  self.changed_image:Hide()

  self.binding_btn = self:AddChild(ImageButton('images/global_redux.xml', 'blank.tex', 'spinner_focus.tex'))
  self.binding_btn:ForceImageSize(button_width, button_height)
  self.binding_btn:SetTextColour(G.UICOLOURS.GOLD_CLICKABLE)
  self.binding_btn:SetTextFocusColour(G.UICOLOURS.GOLD_FOCUS)
  self.binding_btn:SetFont(G.CHATFONT)
  self.binding_btn:SetTextSize(25) -- screens/redux/modconfigurationscreen.lua: same as LabelSpinner's default
  self.binding_btn:SetOnClick(function() self:PopupKeyBindDialog() end)

  self.focus_forward = self.binding_btn
end)

local function Raw(v) return G.rawget(G, v) end -- get keycode

local function Pretty(v)
  if v == 'KEY_DISABLED' then return G.STRINGS.UI.MODSSCREEN.DISABLE end
  return G.STRINGS.UI.CONTROLSSCREEN.INPUTS[1][Raw(v) or 0] -- localized name for the key, or "Unknown"
end

function KeyBindButton:ValidateValue(v) -- code/name of keys like 97/"KEY_A" or 306/"KEY_LCTRL"
  if type(v) == 'string' and v:find('^KEY_') and Raw(v) then self.valid[Raw(v)] = v end
end

function KeyBindButton:SetValue(v)
  if v == self.value then return end
  self.value = v
  self.OnSetValue(v)
  self.binding_btn:SetText(Pretty(v))
  if v == self.initial_value then self.changed_image:Hide() end
  if v ~= self.initial_value then self.changed_image:Show() end
end

function KeyBindButton:PopupKeyBindDialog()
  local body_text = G.STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT
    .. '\n\n'
    .. string.format(G.STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT, Pretty(self.default_value))

  local buttons = { { text = G.STRINGS.UI.CONTROLSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end } }
  if self.allow_disable then
    table.insert(buttons, 1, { -- prepend "Disable" button
      text = G.STRINGS.UI.MODSSCREEN.DISABLE,
      cb = function()
        self:SetValue('KEY_DISABLED')
        TheFrontEnd:PopScreen()
      end,
    })
  end

  local dialog = PopupDialog(self.title, body_text, buttons)
  dialog.OnRawKey = function(_, key, down)
    if down or not self.valid[key] then return end -- wait for releasing valid key
    self:SetValue(self.valid[key])
    TheFrontEnd:PopScreen()
    TheFrontEnd:GetSound():PlaySound('dontstarve/HUD/click_move')
  end

  TheFrontEnd:PushScreen(dialog)
end

-- Repalce config options's Spinner with a KeybindButton like the one from OptionsScreen
AddClassPostConstruct('screens/redux/modconfigurationscreen', function(self)
  if self.modname ~= modname then return end -- avoid messing up other mods
  local keybind_button = 'keybind_button@' .. modname -- avoid being messed up by other mods

  for _, widget in ipairs(self.options_scroll_list.widgets_to_update) do
    local button = KeyBindButton(function(value)
      if value ~= widget.opt.data.initial_value then self:MakeDirty() end
      self.options[widget.real_index].value = value
      widget.opt.data.selected_value = value
      widget:ApplyDescription()
    end)
    button:Hide()
    button:SetPosition(widget.opt.spinner:GetPosition()) -- take original spinner's place

    widget.opt[keybind_button] = widget.opt:AddChild(button)
    widget.opt.focus_forward = function() return button.shown and button or widget.opt.spinner end
  end

  local OldApplyDataToWidget = self.options_scroll_list.update_fn
  self.options_scroll_list.update_fn = function(context, widget, data, ...)
    local result = OldApplyDataToWidget(context, widget, data, ...)
    local button = widget.opt[keybind_button]
    if not (button and data and not data.is_header) then return result end

    for _, v in ipairs(self.config) do
      if v.name == data.option.name then
        if not v.is_keybind then return result end

        button.title = v.label
        button.default_value = v.default
        button.initial_value = data.initial_value
        button:SetValue(data.selected_value)
        for _, option in ipairs(data.option.options) do
          button:ValidateValue(option.data)
          if option.data == 'KEY_DISABLED' then button.allow_disable = true end
        end

        widget.opt.spinner:Hide()
        button:Show()
        return result
      end
    end
  end

  self.options_scroll_list:RefreshView()
end)
