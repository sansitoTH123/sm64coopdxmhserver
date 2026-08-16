-- gp_player_actions_cmd.lua - created by Marioiscool246 on 10/25/2024, last updated on 10/26/2024 MM/DD/YY

function cmd_act_player_set_mashout_enabled(args)
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
        gGlobalSyncTable.mashoutEnabled = value
        store_mashout_enabled(value)
        djui_chat_message_create("Changed Setting mashoutEnabled to " .. tostring(value))
        return true
    end

    return false
end

function cmd_act_player_set_throw_vel_mult(args)
    if (network_is_server() == false) then
        return
    end

    local argValue = args[2]

    if (argValue == nil) then
        return false
    end

    local value = tonumber(argValue)

    if (value ~= nil and value >= 0.0) then
        gGlobalSyncTable.grabThrowMult = value
        store_grab_throw_mult(value)
        djui_chat_message_create("Changed Setting grabThrowMult to " .. tostring(value))
        return true
    end

    return false
end

function cmd_act_player_set_hold_mode(args)
    local argValue = args[2]

    if (argValue == nil) then
        return false
    end

    argValue = string.lower(argValue)

    local grabHoldMode

    if (argValue == 'normal') then
        grabHoldMode = 0
    elseif (argValue == 'bowser') then
        grabHoldMode = 1
    else
        valueNum = tonumber(argValue)
        if (valueNum ~= nil and valueNum < GRAB_HOLD_MODE_MAX) then
            grabHoldMode = valueNum
        end
    end

    if (grabHoldMode ~= nil) then
        gPlayerGrabHoldMode = grabHoldMode
        store_grab_hold_mode(grabHoldMode)
        djui_chat_message_create("Changed Setting grabHoldMode to " .. tostring(grabHoldMode))
        return true
    end

    return false
end

function cmd_act_player_set_hold_mode_swap(args)
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
        gPlayerGrabHoldModeSwap = value
        store_grab_hold_mode_swap(value)
        djui_chat_message_create("Changed Setting grabHoldModeSwap to " .. tostring(value))
        return true
    end

    return false
end

function cmd_act_player_set_allow_hold_mode_swap(args)
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
        gGlobalSyncTable.allowGrabHoldModeSwap = value
        store_allow_grab_hold_mode_swap(value)
        djui_chat_message_create("Changed Setting allowGrabHoldModeSwap to " .. tostring(value))
        return true
    end

    return false
end