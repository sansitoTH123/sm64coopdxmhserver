-- gui_init.lua - created by Marioiscool246 on 2/7/2024, last updated on 10/26/2024 MM/DD/YY

local mainWindowWidth = 500
local mainWindowHeight = 600

local mainWindow = gui_common_new(GUIWindow)
mainWindow:init("Grab Mod Settings", (djui_hud_get_screen_width() - mainWindowWidth) * 0.5, (djui_hud_get_screen_height() - mainWindowHeight) * 0.5, mainWindowWidth, mainWindowHeight)

local gpHostSettingsLabel = gui_common_new(GUISelectableLabel)
gpHostSettingsLabel:set_text("Host Settings")
mainWindow:add_selectable(gpHostSettingsLabel)

local gpToggleMashoutToggle = gui_common_new(GUISelectableToggle)
gpToggleMashoutToggle:set_text("Mashout Enabled")
gpToggleMashoutToggle:set_can_select(network_is_server())
gpToggleMashoutToggle:set_value_callbacks(ui_act_player_get_mashout_enabled, ui_act_player_set_mashout_enabled)
mainWindow:add_selectable(gpToggleMashoutToggle)

local gpThrowMultSelect = gui_common_new(GUISelectableLRSelect)
gpThrowMultSelect:set_text("Throw Force Multiplier")
gpThrowMultSelect:set_can_select(network_is_server())
gpThrowMultSelect:set_value_params(0.5, 2.0, 0.01, 1.0)
gpThrowMultSelect:set_value_callbacks(ui_act_player_get_throw_vel_mult, ui_act_player_set_throw_vel_mult)
mainWindow:add_selectable(gpThrowMultSelect)

local gpGroundPoundBreaksGrabsToggle = gui_common_new(GUISelectableToggle)
gpGroundPoundBreaksGrabsToggle:set_text("Ground Pounds Break Grabs")
gpGroundPoundBreaksGrabsToggle:set_can_select(network_is_server())
gpGroundPoundBreaksGrabsToggle:set_value_callbacks(ui_player_get_groundpound_breaks_grabs, ui_player_set_groundpound_breaks_grabs)
mainWindow:add_selectable(gpGroundPoundBreaksGrabsToggle)

local gpCheckTeamsToggle = gui_common_new(GUISelectableToggle)
gpCheckTeamsToggle:set_text("Check Same Team (Description Colors)")
gpCheckTeamsToggle:set_can_select(network_is_server())
gpCheckTeamsToggle:set_value_callbacks(ui_player_get_check_same_team, ui_player_set_check_same_team)
mainWindow:add_selectable(gpCheckTeamsToggle)

local gpAllowSwapGrabHoldModeToggle = gui_common_new(GUISelectableToggle)
gpAllowSwapGrabHoldModeToggle:set_text("Allow Swap Grab Hold Mode")
gpAllowSwapGrabHoldModeToggle:set_can_select(network_is_server())
gpAllowSwapGrabHoldModeToggle:set_value_callbacks(ui_act_player_get_allow_grab_hold_mode_swap, ui_act_player_set_allow_grab_hold_mode_swap)
mainWindow:add_selectable(gpAllowSwapGrabHoldModeToggle)

local gpHostClientSpacer = gui_common_new(GUISelectableSpacer)
mainWindow:add_selectable(gpHostClientSpacer)

local gpClientSettingsLabel = gui_common_new(GUISelectableLabel)
gpClientSettingsLabel:set_text("Client Settings")
mainWindow:add_selectable(gpClientSettingsLabel)

local gpHoldModeButton = gui_common_new(GUISelectableButton)
gpHoldModeButton:set_text("Grab Hold Mode")
gpHoldModeButton:set_button_width(150)
gpHoldModeButton:set_click_callback(ui_act_player_hold_mode_increment)
gpHoldModeButton:set_get_button_text_callback(ui_act_player_get_hold_mode_name)
mainWindow:add_selectable(gpHoldModeButton)

local gpSwapHoldModeToggle = gui_common_new(GUISelectableToggle)
gpSwapHoldModeToggle:set_text("Swap Grab Hold Mode (L+X)")
gpSwapHoldModeToggle:set_value_callbacks(ui_act_player_get_grab_hold_mode_swap, ui_act_player_set_grab_hold_mode_swap)
mainWindow:add_selectable(gpSwapHoldModeToggle)

GUIMainWindow = mainWindow