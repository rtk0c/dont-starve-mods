-- FIXME the way we're writing over OptionsScreen's methods is not compatible with DST's hotreload.lua (I think)

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local ScrollableList = require "widgets/scrollablelist"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TEMPLATES = require "widgets/redux/templates"
local OptionsScreen = require "screens/redux/optionsscreen"

-- Copy a reference to the mod environment here, the global will be cleared after this chunk exits
local EXPORTS = EXPORTS

local function FindModByID(modid)
  for _, cand in ipairs(ModManager.mods) do
    if cand.modinfo.id == modid then
      return cand
    end
  end
  return nil
end

-- Copied from OptionsScreen:_BuildControls()
function OptionsScreen:_BuildModKeybinds()
  local screen_root = Widget("ROOT")

  screen_root:SetPosition(290,-20)

  local horizontal_line = screen_root:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
  horizontal_line:SetScale(.9)
  horizontal_line:SetPosition(-210, 175)

  local button_x = -371 -- x coord of the left edge
  local button_width = 250
  local button_height = 48
  local label_width = 375
  local spacing = 15

  -- Categorize keybinds by their declared modid
  local keybinds_by_mod = {}
  for _, kbd in ipairs(EXPORTS.keybind_registry) do
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
    local mod = FindModByID(modid)
  
    -- Sort keybinds within each mod's section alphabetically
    table.sort(mod_keybinds, function(a, b) return a.name < b.name end)

    table.insert(keybinds_sections, {
      modid = modid,
      modname = mod and (mod.modinfo.name) or modid,
      keybinds = mod_keybinds,
    })
  end
  table.sort(keybinds_sections, function(a, b) return a.modname < b.modname end)

  -- Create list widgets for sections and keybinds
  local widgets = {}
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
      kw.binding_btn:SetText(EXPORTS.InputMaskToString(kbd:GetInputMask()))

      kw.unbinding_btn = kw:AddChild(ImageButton("images/global_redux.xml", "close.tex", "close.tex"))
      kw.unbinding_btn:SetOnClick(function()
        kbd:SetInputMask(0)
        kw.binding_btn:SetText(EXPORTS.InputMaskToString(0))
      end)
      kw.unbinding_btn:SetPosition(x - 5,0)
      kw.unbinding_btn:SetScale(0.4, 0.4)
      kw.unbinding_btn:SetHoverText(STRINGS.UI.CONTROLSSCREEN.UNBIND)

      kw.focus_forward = kw.binding_btn

      table.insert(widgets, kw)
    end
  end

  local align_to_scroll = screen_root:AddChild(Widget(""))
  align_to_scroll:SetPosition(-160, 200) -- hand-tuned amount that aligns with scrollablelist

  local x = button_x
  x = x + label_width/2
  local actions_header = align_to_scroll:AddChild(Text(HEADERFONT, 30, STRINGS.UI.OPTIONS.ACTION))
  actions_header:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
  actions_header:SetPosition(x-20, 0) -- move a bit towards text
  actions_header:SetRegionSize(label_width, 50)
  actions_header:SetHAlign(ANCHOR_MIDDLE)
  x = x + label_width/2

  local vertical_line = align_to_scroll:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
  vertical_line:SetScale(.7, .43)
  vertical_line:SetRotation(90)
  vertical_line:SetPosition(x, -200)
  vertical_line:SetTint(1,1,1,.1)
  x = x + spacing

  x = x + button_width/2
  local device_header = align_to_scroll:AddChild(Text(HEADERFONT, 30, "Keyboard/Mouse"))
  device_header:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
  device_header:SetPosition(x, 0)
  x = x + button_width/2 + spacing

  local widgetlist = screen_root:AddChild(ScrollableList(widgets, (label_width + spacing + button_width)/2, 420, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "GOLD"))
  widgetlist:SetPosition(0, -50)

  screen_root.focus_forward = widgetlist

  return screen_root
end

function OptionsScreen:_MapKeybind(kbd_widget)
  local default_text = string.format(STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT,
    EXPORTS.InputMaskToString(kbd_widget.keybind:GetInputMask()))
  local body_text = STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT .. "\n\n" .. default_text
  local popup = PopupDialogScreen(kbd_widget.keybind.name, body_text, {})
  popup.dialog.body:SetPosition(0, 0)
  popup.OnControl = function(_, control, down) return true end

  TheFrontEnd:PushScreen(popup)

  EXPORTS.BeginKeychordCapture(function(input_mask)
    kbd_widget.keybind:SetInputMask(input_mask)
    kbd_widget.binding_btn:SetText(EXPORTS.InputMaskToString(input_mask))
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
    TheFrontEnd:PopScreen()
  end)
end

if not OptionsScreen._vanilla_ctor then
  OptionsScreen._vanilla_ctor = OptionsScreen._ctor
end

local old_ctor = OptionsScreen._ctor
function OptionsScreen:_ctor(prev_screen, default_section)
  old_ctor(self, prev_screen, default_section)

  -- Insert our tab after initialization; the alternative is copy and modify the entire self:_BuildMenu() method.
  -- Unfortunately, this forces our Mod Keybinds tab to be the first one in the list--positioning is done in Menu:AddCustomItem(), we can't control that.

  self.subscreener.sub_screens["mod_keybinds"] = self.panel_root:AddChild(self:_BuildModKeybinds())
  self.subscreener.menu:AddCustomItem(self.subscreener:MenuButton("Mod Keybinds", "mod_keybinds", "Rebind mod keybinds", self.tooltip))
  -- We need to call this again (old_ctor already did it) to hide the new panel added above ^^^
  self.subscreener:OnMenuButtonSelected("settings")
end
