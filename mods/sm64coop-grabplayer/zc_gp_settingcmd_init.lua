-- zc_gp_settingcmd_init.lua - created by Marioiscool246 on 10/16/2024, last updated on 10/26/2024 MM/DD/YY

-- add new commands here

local cmd_mashout_enabled = gp_settingcmd_new()
cmd_mashout_enabled:init("sv_mashout_enabled", "Controls the ability for someone being grabbed to escape by pressing the jump button repeatedly", "true/false, 0/1", cmd_act_player_set_mashout_enabled, true)

local cmd_throwforce_mult = gp_settingcmd_new()
cmd_throwforce_mult:init("sv_throwforce_mult", "Controls how far players are thrown from being grabbed", "any positive number", cmd_act_player_set_throw_vel_mult, true)

local cmd_groundpound_breaks_tags = gp_settingcmd_new()
cmd_groundpound_breaks_tags:init("sv_groundpound_breaks_grabs", "Controls whether players can break grabs between two other players by ground pounding them", "true/false, 0/1", cmd_player_set_groundpound_breaks_grabs, true)

local cmd_check_same_team = gp_settingcmd_new()
cmd_check_same_team:init("sv_check_same_team", "Controls whether players on the same team (same description colors) cannot grab eachother", "true/false, 0/1", cmd_player_set_check_same_team, true)

local cmd_allow_grab_hold_mode_swap = gp_settingcmd_new()
cmd_allow_grab_hold_mode_swap:init("sv_allow_grab_hold_mode_swap", "Controls whether players are allowed to swap their grab hold mode while grabbing another players", "true/false, 0/1", cmd_act_player_set_allow_hold_mode_swap, true)

local cmd_grab_hold_mode = gp_settingcmd_new()
cmd_grab_hold_mode:init("cl_grab_hold_mode", "Controls the grab type when grabbing other players", "normal/bowser, 0-1", cmd_act_player_set_hold_mode, false)

local cmd_grab_hold_mode_swap = gp_settingcmd_new()
cmd_grab_hold_mode_swap:init("cl_grab_hold_mode_swap", "Controls the ability to change grab hold modes while grabbing another player", "true/false, 0/1", cmd_act_player_set_hold_mode_swap, false)

-- create the gp_settings command

local function cmd_gp_settings(msg)
    -- split up the command
    local args = {}
    for arg in string.gmatch(msg, "[^%s]+") do
        table.insert(args, arg)
    end

    if (#args == 0) then
        if (is_game_paused() ~= false) then
            djui_chat_message_create("Pause menu must be closed to toggle the GUI")
            return true
        end

        gui_toggle()
        return true
    end

    local cmdName = args[1]

    if (string.lower(cmdName) == "help") then
        djui_chat_message_create("\\#FFFF00\\Grab Mod Setting commands:")

        for i, settingCmd in pairs(GPSettingCommands) do
            settingCmd:print_help()
        end

        return true
    end

    for i, settingCmd in pairs(GPSettingCommands) do
        if (cmdName == settingCmd.name) then
            settingCmd:execute(args)
            return true
        end
    end

    djui_chat_message_create("\\#FF4040\\Grab Mod Setting command not found\nUse '/gp_settings help' for a valid list of commands")

    return true
end

hook_chat_command("gp_settings", "- View or change settings with the grab mod settings interface or with subcommands", cmd_gp_settings)