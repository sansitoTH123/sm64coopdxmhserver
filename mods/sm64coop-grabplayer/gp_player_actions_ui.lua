-- gp_player_actions_ui.lua - created by Marioiscool246 on 10/25/2024, last updated on 10/26/2024 MM/DD/YY

function ui_act_player_get_mashout_enabled()
    return gGlobalSyncTable.mashoutEnabled
end

function ui_act_player_set_mashout_enabled(value)
    if (network_is_server() == false) then
        return
    end

    gGlobalSyncTable.mashoutEnabled = value
    store_mashout_enabled(value)
end

function ui_act_player_get_throw_vel_mult()
    return gGlobalSyncTable.grabThrowMult
end

function ui_act_player_set_throw_vel_mult(value)
    if (network_is_server() == false) then
        return
    end

    gGlobalSyncTable.grabThrowMult = value
    store_grab_throw_mult(value)
end

function ui_act_player_hold_mode_increment()
    act_player_hold_mode_increment()
    return true
end

function ui_act_player_get_hold_mode_name()
    local grabHoldModeName = gPlayerGrabHoldModeNames[gPlayerGrabHoldMode]

    if (grabHoldModeName == nil) then
        return "Normal"
    end

    return grabHoldModeName
end

function ui_act_player_get_grab_hold_mode_swap()
    return gPlayerGrabHoldModeSwap
end

function ui_act_player_set_grab_hold_mode_swap(value)
    gPlayerGrabHoldModeSwap = value
    store_grab_hold_mode_swap(value)
end

function ui_act_player_get_allow_grab_hold_mode_swap()
    return gGlobalSyncTable.allowGrabHoldModeSwap
end

function ui_act_player_set_allow_grab_hold_mode_swap(value)
    if (network_is_server() == false) then
        return
    end

    gGlobalSyncTable.allowGrabHoldModeSwap = value
    store_allow_grab_hold_mode_swap(value)
end