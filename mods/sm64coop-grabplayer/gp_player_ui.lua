-- gp_player_ui.lua - created by Marioiscool246 on 10/25/2024, last updated on 10/26/2024 MM/DD/YY

function ui_player_get_groundpound_breaks_grabs()
    return gGlobalSyncTable.groundPoundsBreaksGrabs
end

function ui_player_set_groundpound_breaks_grabs(value)
    if (network_is_server() == false) then
        return
    end

    gGlobalSyncTable.groundPoundsBreaksGrabs = value
    store_ground_pound_breaks_grabs(value)
end

function ui_player_get_check_same_team()
    return gGlobalSyncTable.checkSameTeam
end

function ui_player_set_check_same_team(value)
    if (network_is_server() == false) then
        return
    end

    gGlobalSyncTable.checkSameTeam = value
    store_check_same_team(value)
end