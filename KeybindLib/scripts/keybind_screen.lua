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

-- The same function provided to modinfo
local function T(tbl)
  local locale = LOC.GetLocaleCode()
  return tbl[locale] or tbl[1]
end

local function MakeSectionHeader(title)
  local header = Widget("SectionHeader")
  header.txt = header:AddChild(Text(HEADERFONT, 30, title, UICOLOURS.GOLD_SELECTED))
  header.txt:SetPosition(-60, 0)
  header.bg = header:AddChild(TEMPLATES.ListItemBackground(700, 48)) -- only to be more scrollable
  header.bg:SetImageNormalColour(0, 0, 0, 0) -- total transparent
  header.bg:SetImageFocusColour(0, 0, 0, 0)
  header.bg:SetPosition(-60, 0)
  header.bg:SetScale(1.025, 1)
  return header
end

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

  -- Categorize keybinds by their declared modname
  local keybinds_by_mod = {}
  for _, kbd in ipairs(KeybindLib.keybind_registry) do
    local mod_key = kbd.modname and kbd.modname or "<unknown>"
    local mod_keybinds = keybinds_by_mod[mod_key]
    if not mod_keybinds then
      mod_keybinds = {}
      keybinds_by_mod[mod_key] = mod_keybinds
    end

    table.insert(mod_keybinds, kbd)
  end

  -- Sort mod's section alphabetically
  local keybinds_sections = {}
  for modname, mod_keybinds in pairs(keybinds_by_mod) do
    -- Sort keybinds within each mod's section alphabetically
    table.sort(mod_keybinds, function(a, b) return a.name < b.name end)

    table.insert(keybinds_sections, {
      modname = modname,
      modname = KnownModIndex:GetModFancyName(modname),
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
    local modname = section.modname
    local modname = section.modname

    table.insert(widgets, MakeSectionHeader(modname))

    for _, kbd in ipairs(section.keybinds) do
      -- "Keybind Widget"
      local kw = Widget(modname .. ":" .. kbd.id)
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
      kw.binding_btn:SetOnClick(function()
        -- On Windows (but not Linux, macOS), the mouse click to binding_btn will immediately be caught by the popup
        -- Delay by 1 frame to workaround this issue
        self.inst:DoTaskInTime(0, function() self:_MapKeybind(kw) end)
      end)
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
  local body_text = STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT
    .. "\n\n"
    .. string.format(STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT, KeybindLib:LocalizeInputMask(kbd_widget.keybind.default_input_mask))

  local is_canceled = false
  local popup = PopupDialogScreen(kbd_widget.keybind.name, body_text, {
    {
      text = STRINGS.UI.CONTROLSSCREEN.CANCEL,
      cb = function()
        TheFrontEnd:PopScreen()
      end,
    },
  })

  local key_capturer = function(_, key, down)
    -- Delay by 1 frame to let the dialog buttons can signal us
    -- By default, OnRawKey and OnMouseButton of this parent widget is called before the buttons are
    self.inst:DoTaskInTime(0, function()
      -- If the cancel button is clicked, don't capture the mouse click
      if is_canceled then return end

      -- Keep taking input until a non-modifier key release
      if not down and not KeybindLib.MODIFIER_KEYS[key] then
        local mod_mask = KeybindLib:GetModifiersMaskNow()
        local input_mask = bit.bor(mod_mask, key)

        self:_UserChangeKeybind(kbd_widget, input_mask)
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        TheFrontEnd:PopScreen()
      end
    end)
  end
  popup.OnRawKey = key_capturer
  popup.OnMouseButton = key_capturer

  TheFrontEnd:PushScreen(popup)
end

local old_BuildMenu = OptionsScreen._BuildMenu
function OptionsScreen:_BuildMenu(subscreener)
  -- Initialize fields (as-if doing this at the end of _ctor)
  self._mapping_changes = {}

  -- Add the Mod Keybinds screen
  local mod_keybinds_screen = self:_BuildModKeybinds()
  subscreener.sub_screens["mod_keybinds"] = self.panel_root:AddChild(mod_keybinds_screen)

  -- Add the button that jumps to Mod Keybinds screen
  -- See the original OptionsScreen:_BuildMenu(), addition details here:
  --   _BuildMenu() 函数会构造一个列表，其中包含了各个标签页对应的 subscreener:MenuButton() 菜单项。函数最后把这个传给 TEMPLATES.StandardMenu()，构造屏幕左侧那个切换标签页用的菜单栏。
  --   我们要把 mod_keybinds_button 插入到那个列表中，“控制”标签页对应的菜单项的前面（从而达到显示在它下面的效果，因为 StandardMenu 默认是反转列表顺序的）
  --   而唯一能在构造列表后、TEMPLATES.StandardMenu() 函数执行前插入代码的方法，就是临时替换掉 StandardMenu 为要做的准备工作，再在做完后跳转回原来的 StandardMenu。
  local old_TEMPLATES_StandardMenu = TEMPLATES.StandardMenu
  TEMPLATES.StandardMenu = function(menuitems, offset, horizontal, style, wrap) 
    -- Construct our button for switching to our screen
    -- This must be called at the end of the original _BuildMenu(), because self.tooltip is initialized at its top
    local name = T({"Mod Keybinds", zh="模组快捷键", zht="模組快捷鍵"})
    local description = T({"Rebind custom keybinds added by mods", zh="重新绑定模组添加的自定义快捷键", zht="重新綁定模組添加的自定義快捷鍵"})
    local mod_keybinds_button = subscreener:MenuButton(name, "mod_keybinds", description, self.tooltip)

    -- Find "controls" in menuitems, and put our button before that
    local target_text = STRINGS.UI.OPTIONS.CONTROLS
    for i, menu_item in ipairs(menuitems) do
      if menu_item.widget:GetText() == target_text then
        table.insert(menuitems, i, {widget = mod_keybinds_button})
        break
      end
    end

    TEMPLATES.StandardMenu = old_TEMPLATES_StandardMenu
    return old_TEMPLATES_StandardMenu(menuitems, offset, horizontal, style, wrap)
  end
  return old_BuildMenu(self, subscreener)
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
  local reg = KeybindLib.keybind_registry
  for full_id, new_input_mask in pairs(self._mapping_changes) do
    reg[full_id]:SetInputMask(new_input_mask)
  end
  KeybindLib:SaveKeybindMappings()
  
  return old_Save(self, cb)
end

-- No-op for revert changes, just throw away self._mapping_changes is enough
--[[
local old_RevertChanges = OptionsScreen.RevertChanges
function OptionsScreen:RevertChanges()
  old_RevertChanges(self)
end
--]]
