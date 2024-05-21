-- NOTE: this file runs with GLOBAL environment

-- FIXME the way we're writing over OptionsScreen's methods is not compatible with DST's hotreload.lua (I think)

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local ScrollableList = require "widgets/scrollablelist"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TEMPLATES = require "widgets/redux/templates"
local OptionsScreen = require "screens/redux/optionsscreen"

-- Copied from OptionsScreen:_BuildControls()
function OptionsScreen:_BuildModKeybinds()
  local screen_root = Widget("ROOT")

  screen_root:SetPosition(290,-20)

  -- Copied from MakeSpinnerTooltip() in optionsscreen.lua
  local tooltip = screen_root:AddChild(Text(CHATFONT, 25, ""))
  tooltip:SetPosition(-210, -275)
  tooltip:SetHAlign(ANCHOR_LEFT)
  tooltip:SetVAlign(ANCHOR_TOP)
  tooltip:SetRegionSize(800, 80)
  tooltip:EnableWordWrap(true)

  -- Copied from various OptionsScreen:_BuildSettings(), etc.
  local tooltip_divider = screen_root:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
  tooltip_divider:SetPosition(-210, -225)
  tooltip_divider:Hide()

  local button_x = -371 -- x coord of the left edge
  local button_width = 250
  local button_height = 48
  local label_width = 375
  local spacing = 15

  -- Categorize keybinds by their declared modid
  local keybinds_by_mod = {}
  for _, kbd in ipairs(KeybindLib.keybind_registry) do
    local mod_key = kbd.modid and kbd.modid or "<unknown>"
    local mod_keybinds = keybinds_by_mod[mod_key]
    if not mod_keybinds then
      mod_keybinds = {}
      keybinds_by_mod[mod_key] = mod_keybinds
    end

    table.insert(mod_keybinds, kbd)
  end

  -- Sort mod's section alphabetically
  local keybinds_sections = {}
  for modid, mod_keybinds in pairs(keybinds_by_mod) do
    -- Sort keybinds within each mod's section alphabetically
    table.sort(mod_keybinds, function(a, b) return a.name < b.name end)

    table.insert(keybinds_sections, {
      modid = modid,
      modname = KnownModIndex:GetModFancyName(modid),
      keybinds = mod_keybinds,
    })
  end
  table.sort(keybinds_sections, function(a, b) return a.modname < b.modname end)

  local widgets = {}

  local header = Widget("")

  local horizontal_line = header:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
  horizontal_line:SetScale(.85)
  horizontal_line:SetPosition(-63, -15)

  local x = button_x
  x = x + label_width/2
  local actions_header = header:AddChild(Text(HEADERFONT, 30, STRINGS.UI.OPTIONS.ACTION))
  actions_header:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
  actions_header:SetPosition(x - 20, 10) -- move a bit towards text
  actions_header:SetRegionSize(label_width, 50)
  actions_header:SetHAlign(ANCHOR_MIDDLE)
  x = x + label_width/2

  -- NOTE: this is a child of screen_root
  local vertical_line = screen_root:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
  vertical_line:SetScale(.7, .43)
  vertical_line:SetRotation(90)
  vertical_line:SetPosition(-156, 0)
  -- The x = -160 came from align_to_scroll in vanilla's code's x coordinate
  -- Since vertical_line used to be a child of it, we just add the x coordinates for correction
  -- The y = 0 came from the same thing. 200 + -200 = 0
  vertical_line:SetPosition(-160 + x, 0)
  vertical_line:SetTint(1,1,1,.1)
  x = x + spacing

  x = x + button_width/2
  local device_header = header:AddChild(Text(HEADERFONT, 30, STRINGS.UI.CONTROLSSCREEN.INPUT_NAMES[1]))
  device_header:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
  device_header:SetPosition(x, 10)
  x = x + button_width/2 + spacing

  table.insert(widgets, header)

  -- Create list widgets for sections and keybinds
  for _, section in ipairs(keybinds_sections) do
    local modid = section.modid
    local modname = section.modname

    local section_title = Text(HEADERFONT, 30, modname)
    section_title:SetHAlign(ANCHOR_MIDDLE)
    section_title:SetColour(UICOLOURS.GOLD_SELECTED)

    table.insert(widgets, section_title)

    for _, kbd in ipairs(section.keybinds) do
      -- "Keybind Widget"
      local kw = Widget(modid .. ":" .. kbd.id)
      kw.bg = kw:AddChild(TEMPLATES.ListItemBackground(700, button_height))
      kw.bg:SetPosition(-60,0)
      kw.bg:SetScale(1.025, 1)
      kw:SetScale(1,1,0.75)

      kw.keybind = kbd

      local x = button_x

      kw.label = kw:AddChild(Text(CHATFONT, 28))
      kw.label:SetString(kbd.name)
      kw.label:SetHAlign(ANCHOR_LEFT)
      kw.label:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
      kw.label:SetRegionSize(label_width, 50)
      x = x + label_width/2
      kw.label:SetPosition(x,0)
      x = x + label_width/2 + spacing
      kw.label:SetClickable(false)

      x = x + button_width/2
      kw.changed_image = kw:AddChild(Image("images/global_redux.xml", "wardrobe_spinner_bg.tex"))
      kw.changed_image:SetTint(1,1,1,0.3)
      kw.changed_image:ScaleToSize(button_width, button_height)
      kw.changed_image:SetPosition(x,0)
      kw.changed_image:Hide()

      kw.binding_btn = kw:AddChild(ImageButton("images/global_redux.xml", "blank.tex", "spinner_focus.tex"))
      kw.binding_btn:ForceImageSize(button_width, button_height)
      kw.binding_btn:SetTextColour(UICOLOURS.GOLD_CLICKABLE)
      kw.binding_btn:SetTextFocusColour(UICOLOURS.GOLD_FOCUS)
      kw.binding_btn:SetFont(CHATFONT)
      kw.binding_btn:SetTextSize(30)
      kw.binding_btn:SetPosition(x,0)
      kw.binding_btn:SetOnClick(function() self:_MapKeybind(kw) end)
      x = x + button_width/2 + spacing

      kw.binding_btn:SetHelpTextMessage(STRINGS.UI.CONTROLSSCREEN.CHANGEBIND)
      kw.binding_btn:SetDisabledFont(CHATFONT)
      kw.binding_btn:SetText(KeybindLib:LocalizeInputMask(kbd:GetInputMask()))

      kw.unbinding_btn = kw:AddChild(ImageButton("images/global_redux.xml", "close.tex", "close.tex"))
      kw.unbinding_btn:SetOnClick(function() self:_UnmapKeybind(kw) end)
      kw.unbinding_btn:SetPosition(x - 5,0)
      kw.unbinding_btn:SetScale(0.4, 0.4)
      kw.unbinding_btn:SetHoverText(STRINGS.UI.CONTROLSSCREEN.UNBIND)

      -- Copied from AddSpinnerTooltip() in optionsscreen.lua
      local function ongainfocus(is_enabled)
        local desc = kbd.description
        if desc then
          tooltip:SetString(desc)
          tooltip_divider:Show()
        end
      end
      kw.bg.ongainfocus = ongainfocus
      -- If we don't do this, hovering on this btn doesn't show tooltip
      -- So it seems like Button() doesn't let focus propagate through it?
      -- FIXME mouse exiting binding_btn does not unset tooltip?
      kw.binding_btn.ongainfocus = ongainfocus
      local function onlosefocus(is_enabled)
        if kw.parent and not kw.parent.focus then
          tooltip:SetString("")
          tooltip_divider:Hide()
        end
      end
      kw.bg.onlosefocus = onlosefocus
      kw.binding_btn.onlosefocus = onlosefocus

      kw.focus_forward = kw.binding_btn

      table.insert(widgets, kw)
    end
  end

  -- FIXME for some reason, if cursor is in the gap between keybinds, AND is on the left side of the frame, then scroll doesn't work
  --       similarly doesn't work only if is on the left side of section title
  local widgetlist = screen_root:AddChild(ScrollableList(widgets, (label_width + spacing + button_width)/2, 400, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "GOLD"))
  widgetlist:SetPosition(0, 5)

  screen_root.focus_forward = widgetlist

  return screen_root
end

function OptionsScreen:_UserChangeKeybind(kbd_widget, new_input_mask)
  local kbd = kbd_widget.keybind

  -- Save changes to buffer
  self._mapping_changes[kbd.full_id] = new_input_mask

  -- Display changes on screen
  kbd_widget.binding_btn:SetText(KeybindLib:LocalizeInputMask(new_input_mask))
  if kbd:GetInputMask() ~= new_input_mask then
    kbd_widget.changed_image:Show()
    if not self:IsDirty() then
      self:MakeDirty()
    end
  else
    kbd_widget.changed_image:Hide()
  end
end

function OptionsScreen:_UnmapKeybind(kbd_widget)
  self:_UserChangeKeybind(kbd_widget, 0)
  TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
end

function OptionsScreen:_MapKeybind(kbd_widget)
  local default_text = string.format(STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT,
    KeybindLib:LocalizeInputMask(kbd_widget.keybind.default_input_mask))
  local body_text = STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT .. "\n\n" .. default_text
  local popup = PopupDialogScreen(kbd_widget.keybind.name, body_text, {})
  popup.dialog.body:SetPosition(0, 0)

  popup.OnControl = function(_, control, down) return true end

  local key_capturer = function(_, key, down)
    -- Keep taking input until a non-modifier key release
    if not down and not KeybindLib.MODIFIER_KEYS[key] then
      local mod_mask = KeybindLib:GetModifiersMaskNow()
      local input_mask = bit.bor(mod_mask, key)

      self:_UserChangeKeybind(kbd_widget, input_mask)
      TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
      TheFrontEnd:PopScreen()
    end
  end
  popup.OnRawKey = key_capturer
  popup.OnMouseButton = key_capturer

  TheFrontEnd:PushScreen(popup)
end

local old_ctor = OptionsScreen._ctor
function OptionsScreen:_ctor(prev_screen, default_section)
  old_ctor(self, prev_screen, default_section)

  self._mapping_changes = {}

  -- Insert our tab after initialization; the alternative is copy and modify the entire self:_BuildMenu() method.
  -- Unfortunately, this forces our Mod Keybinds tab to be the first one in the list--positioning is done in Menu:AddCustomItem(), we can't control that.

  self.subscreener.sub_screens["mod_keybinds"] = self.panel_root:AddChild(self:_BuildModKeybinds())
  self.subscreener.menu:AddCustomItem(self.subscreener:MenuButton("Mod Keybinds", "mod_keybinds", "Rebind mod keybinds", self.tooltip))
  -- We need to call this again (old_ctor already did it) to hide the new panel added above ^^^
  self.subscreener:OnMenuButtonSelected("settings")
end

-- The option saving codepath is a confusing labyrinth.
-- From what I can tell, depending on what the user does (clicking Apply? clicking Back? using controller's back button?)
-- the logic starts at various different functions that are irrelevant to us, but everythings ends up at some point calling either:
-- * :ConfirmApply() -> :Save() -> :Apply() -> ...
--   note that self:ApplyVolume() is called here, but self:ApplyChanges() is something that sits before this chain
-- * :ConfirmRevert() -> :RevertChanges() -> :Apply() -> ...
-- depending on if the user chose to save or to discard changes.
-- Vanilla save the controls in self:Apply(), but we don't have an extra indirection, so we must go one level higher.

local old_Save = OptionsScreen.Save
function OptionsScreen:Save(cb)
  old_Save(self, cb)

  local reg = KeybindLib.keybind_registry
  for full_id, new_input_mask in pairs(self._mapping_changes) do
    reg[full_id]:SetInputMask(new_input_mask)
  end
  KeybindLib:SaveKeybindMappings()
end

-- No-op for revert changes, just throw away self._mapping_changes is enough
--[[
local old_RevertChanges = OptionsScreen.RevertChanges
function OptionsScreen:RevertChanges()
  old_RevertChanges(self)
end
--]]
