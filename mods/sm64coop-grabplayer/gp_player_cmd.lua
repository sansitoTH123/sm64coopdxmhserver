-- gp_player_cmd.lua - created by Marioiscool246 on 10/25/2024, last updated on 10/26/2024 MM/DD/YY

function cmd_player_set_groundpound_breaks_grabs(args)
    if (network_is_server() == false) then
        return
    end

    local argValue = args[2]

    if (argValue == nil) then
        return false
    end

    argValue = string.lower(argValue)

    local value

    if (argValue == 'false' or argValue == '0') then
        value = false
    elseif (argValue == 'true' or argValue == '1') then
        value = true
    end

    if (value ~= nil) then
        gGlobalSyncTable.groundPoundsBreaksGrabs = value
        store_ground_pound_breaks_grabs(value)
        djui_chat_message_create("Changed Setting groundPoundsBreaksGrabs to " .. tostring(value))
        return true
    end

    return false
end

function cmd_player_set_check_same_team(args)
    if (network_is_server() == false) then
        return
    end

    local argValue = args[2]

    if (argValue == nil) then
        return false
    end

    argValue = string.lower(argValue)

    local value

    if (argValue == 'false' or argValue == '0') then
        value = false
    elseif (argValue == 'true' or argValue == '1') then
        value = true
    end

    if (value ~= nil) then
        gGlobalSyncTable.checkSameTeam = value
        store_check_same_team(value)
        djui_chat_message_create("Changed Setting checkSameTeam to " .. tostring(value))
        return true
    end

    return false
end