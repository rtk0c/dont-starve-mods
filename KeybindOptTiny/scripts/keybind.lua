local G = GLOBAL

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TEMPLATES = require "widgets/redux/templates"

local _keybinds = {}
local _pending_changes = {}

local function LocalizeKey(key)
  -- If key is unset, return the string for "- No Bind -"
  if key == 0 then return G.STRINGS.UI.CONTROLSSCREEN.INPUTS[9][2] end
  return G.STRINGS.UI.CONTROLSSCREEN.INPUTS[1][key]
end

local function UserChangeKeybind(opt_screen, kbd, kw, new_key)
  _pending_changes[kbd] = new_key

  -- Display changes on screen
  kw.binding_btn:SetText(LocalizeKey(new_key))
  if kbd.key ~= new_key then
    kw.changed_image:Show()
    if not opt_screen:IsDirty() then
      opt_screen:MakeDirty()
    end
  else
    kw.changed_image:Hide()
  end
end

local function MakeKeybindGroup(opt_screen, kbd)
  local button_x = -371 -- x coord of the left edge
  local button_width = 250
  local button_height = 48
  local label_width = 375
  local spacing = 15

  local kw = Widget(modinfo.name .. ":" .. kbd.name)
  kw.bg = kw:AddChild(TEMPLATES.ListItemBackground(700, button_height))
  kw.bg:SetPosition(-60,0)
  kw.bg:SetScale(1.025, 1)
  kw:SetScale(1,1,0.75)

  local x = button_x

  local label = kw:AddChild(Text(G.CHATFONT, 28))
  label:SetString(kbd.name)
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
    local popup = PopupDialogScreen(kbd.name, g_strs.CONTROL_SELECT .. "\n\n" .. default_text, {})
    popup.dialog.body:SetPosition(0, 0)

    popup.OnControl = function(_, control, down) return true end

    popup.OnRawKey = function(_, key, down)
      if not down then
        UserChangeKeybind(opt_screen, kbd, kw, key)
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
    UserChangeKeybind(opt_screen, kbd, kw, 0)
  end)
  unbinding_btn:SetPosition(x - 5,0)
  unbinding_btn:SetScale(0.4, 0.4)
  unbinding_btn:SetHoverText(G.STRINGS.UI.CONTROLSSCREEN.UNBIND)
  kw.unbinding_btn = unbinding_btn

  kw.focus_forward = kw.binding_btn

  return kw
end

local OptionsScreen = require "screens/redux/optionsscreen"
local old_OptionsScreen_Save = OptionsScreen.Save
function OptionsScreen:Save(cb)
  for kbd, new_key in pairs(_pending_changes) do
    kbd.key = new_key
    kbd.on_change(new_key)
  end
  _pending_changes = {}

  return old_OptionsScreen_Save(self, cb)
end
local old_OptionsScreen_RevertChanges = OptionsScreen.RevertChanges
function OptionsScreen:RevertChanges()
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
  table.insert(items, clist:AddChild(section_title))

  for _, kbd in ipairs(_keybinds) do
    local kw = MakeKeybindGroup(self, kbd)
    table.insert(items, clist:AddChild(kw))
  end

  clist:SetList(items, true)
end)

KeybindHandler = {}
function KeybindHandler:Add(name, key, on_change)
  table.insert(_keybinds, {
    name = name,
    default_key = key,
    key = key,
    on_change = on_change
  })
end
