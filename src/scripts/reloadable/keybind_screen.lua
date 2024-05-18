-- FIXME the way we're writing over OptionsScreen's methods is not compatible with DST's hotreload.lua (I think)

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local ScrollableList = require "widgets/scrollablelist"
local TEMPLATES = require "widgets/redux/templates"
local OptionsScreen = require "screens/redux/optionsscreen"

local function InputMaskFromString(str)
	-- TODO
	return 0
end

local function InputMaskToString(v)
	-- TODO
	return ""
end

-- Copy a reference to the mod environment here, the global will be cleared after this chunk exits
local EXPORTS = EXPORTS

-- Copied from OptionsScreen:_BuildControls()
function OptionsScreen:_BuildModKeybinds()
    local kbdscreen_root = Widget("ROOT")

    kbdscreen_root:SetPosition(290,-20)

	local horizontal_line = kbdscreen_root:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
    horizontal_line:SetScale(.9)
    horizontal_line:SetPosition(-210, 175)

	local button_x = -371 -- x coord of the left edge
    local button_width = 250
    local button_height = 48
    local label_width = 375
    local spacing = 15

    local keybind_list = EXPORTS.kbd_list
    local kbd_widgets = {}

    for i, kbd in ipairs(keybind_list) do
        local group = Widget("keybind:" .. kbd.id)
        group.bg = group:AddChild(TEMPLATES.ListItemBackground(700, button_height))
        group.bg:SetPosition(-60,0)
        group.bg:SetScale(1.025, 1)
        group:SetScale(1,1,0.75)

        group.keybind = kbd

        local x = button_x

        group.label = group:AddChild(Text(CHATFONT, 28))
        group.label:SetString(kbd.name)
        group.label:SetHAlign(ANCHOR_LEFT)
        group.label:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
        group.label:SetRegionSize(label_width, 50)
        x = x + label_width/2
        group.label:SetPosition(x,0)
        x = x + label_width/2 + spacing
        group.label:SetClickable(false)

        x = x + button_width/2
        group.changed_image = group:AddChild(Image("images/global_redux.xml", "wardrobe_spinner_bg.tex"))
        group.changed_image:SetTint(1,1,1,0.3)
        group.changed_image:ScaleToSize(button_width, button_height)
        group.changed_image:SetPosition(x,0)
        group.changed_image:Hide()

        group.binding_btn = group:AddChild(ImageButton("images/global_redux.xml", "blank.tex", "spinner_focus.tex"))
        group.binding_btn:ForceImageSize(button_width, button_height)
        group.binding_btn:SetTextColour(UICOLOURS.GOLD_CLICKABLE)
        group.binding_btn:SetTextFocusColour(UICOLOURS.GOLD_FOCUS)
        group.binding_btn:SetFont(CHATFONT)
        group.binding_btn:SetTextSize(30)
        group.binding_btn:SetPosition(x,0)
        group.binding_btn:SetOnClick(function() self:_MapKeybind(group) end)
        x = x + button_width/2 + spacing

        group.binding_btn:SetHelpTextMessage(STRINGS.UI.CONTROLSSCREEN.CHANGEBIND)
        group.binding_btn:SetDisabledFont(CHATFONT)
        group.binding_btn:SetText(InputMaskToString(kbd.input_mask))

		group.unbinding_btn = group:AddChild(ImageButton("images/global_redux.xml", "close.tex", "close.tex"))
		group.unbinding_btn:SetOnClick(function()
			kbd.input_mask = 0
			group.binding_btn:SetText(InputMaskToString(0))
		end)
		group.unbinding_btn:SetPosition(x - 5,0)
		group.unbinding_btn:SetScale(0.4, 0.4)
		group.unbinding_btn:SetHoverText(STRINGS.UI.CONTROLSSCREEN.UNBIND)

        group.focus_forward = group.binding_btn

        table.insert(kbd_widgets, group)
    end

    local align_to_scroll = kbdscreen_root:AddChild(Widget(""))
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

	local kbd_widgetlist = kbdscreen_root:AddChild(ScrollableList(kbd_widgets, (label_width + spacing + button_width)/2, 420, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "GOLD"))
	kbd_widgetlist:SetPosition(0, -50)

    kbdscreen_root.focus_forward = kbd_widgetlist

    return kbdscreen_root
end

function OptionsScreen:_MapKeybind(kbd_widget)
	-- TODO
end

-- FIXME do this more sustainably
function OptionsScreen:_BuildMenu(subscreener)
    self.tooltip = self.root:AddChild(TEMPLATES.ScreenTooltip())

    local menu_items = {
        -- BEGIN MOD
		-- TODO localize
        {widget = subscreener:MenuButton("Mod Keybinds", "mod_keybinds", "Rebind mod keybinds", self.tooltip)},
        -- END MOD
        {widget = subscreener:MenuButton(STRINGS.UI.OPTIONS.CONTROLS, "controls", STRINGS.UI.OPTIONS.TOOLTIPS.CONTROLS, self.tooltip)},
		{widget = subscreener:MenuButton(STRINGS.UI.OPTIONS.ADVANCED, "advanced", STRINGS.UI.OPTIONS.TOOLTIPS.ADVANCED, self.tooltip)},
        {widget = subscreener:MenuButton(STRINGS.UI.OPTIONS.GRAPHICS, "graphics", STRINGS.UI.OPTIONS.TOOLTIPS.GRAPHICS, self.tooltip)},
        {widget = subscreener:MenuButton(STRINGS.UI.OPTIONS.SETTINGS, "settings", STRINGS.UI.OPTIONS.TOOLTIPS.SETTINGS, self.tooltip)},
    }
    if self.show_language_options then
        table.insert(menu_items, 1, {widget = subscreener:MenuButton(STRINGS.UI.OPTIONS.LANGUAGES, "languages", STRINGS.UI.OPTIONS.TOOLTIPS.LANGUAGES, self.tooltip)})
    end

    return self.root:AddChild(TEMPLATES.StandardMenu(menu_items, 38, nil, nil, true))
end

local old_ctor = OptionsScreen._ctor
function OptionsScreen:_ctor(prev_screen, default_section)
	old_ctor(self, prev_screen, default_section)
    self.subscreener.sub_screens["mod_keybinds"] = self.panel_root:AddChild(self:_BuildModKeybinds())
    -- We need to call this again (old_ctor already did it) to hide the new panel added above ^^^
    self.subscreener:OnMenuButtonSelected("settings")
end
