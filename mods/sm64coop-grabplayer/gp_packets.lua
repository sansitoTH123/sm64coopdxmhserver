-- gp_packets.lua - created by Marioiscool246 on 1/11/2024, last updated on 10/26/2024 MM/DD/YY

local PACKET_GRAB_REQUEST = 1
local PACKET_GRAB_REQUEST_RESPONSE = 2
local PACKET_GRAB_RELEASE = 3
local PACKET_GRAB_HOLD = 4
local PACKET_GRAB_STATE_SYNC = 5

local sGrabStateSyncTimer = 0
local sGrabStateSyncSequence = 0

function packet_update()
    if (sGrabStateSyncTimer == 0) then
        send_grab_state_sync(0, false)
    else
        sGrabStateSyncTimer = sGrabStateSyncTimer - 1
    end
end

local function packet_check_receive_ids(dataTable)
    local senderId = dataTable.sendGlobalId
    if (senderId < 0 or senderId >= MAX_PLAYERS) then
        return false
    end

    local recvId = dataTable.recvGlobalId
    if (recvId < 0 or recvId >= MAX_PLAYERS) then
        return false
    end

    return true
end

local function packet_check_receive_id(dataTable)
    local index = dataTable.globalIndex

    return index >= 0 and index < MAX_PLAYERS
end

function send_grab_request(attackerIndex, victimIndex)
    if (attackerIndex ~= 0) then
        return
    end

    local victimGrabState = gPlayerGrabStates[victimIndex]

    if (victimGrabState.sentGrabRequest ~= false) then
        return
    end

    victimGrabState.sentGrabRequest = true
    victimGrabState.sentGrabRequestTimeout = 15

    local attackerGlobalId = network_global_index_from_local(attackerIndex)
    local victimGlobalId = network_global_index_from_local(victimIndex)

    local dataTable = { packetId = PACKET_GRAB_REQUEST,
                        sendGlobalId = attackerGlobalId,
                        recvGlobalId = victimGlobalId }

    network_send(true, dataTable)
end

local function check_grab_request(grabPlayer, grabPlayerVictim)
    local grabPlayerLocalIndex = grabPlayer.playerIndex
    local grabPlayerVictimLocalIndex = grabPlayerVictim.playerIndex

    if (gPlayerGrabStates[grabPlayerLocalIndex].sentGrabRequest ~= false) then
        return false
    end

    if (player_is_grabbing(grabPlayerLocalIndex) ~= false or player_is_grabbing(grabPlayerVictimLocalIndex) ~= false) then
        return false
    end

    if (is_player_active(grabPlayer) == 0) then
        return false
    end

    if (player_check_same_team(grabPlayer, grabPlayerVictim) ~= false) then
        return false
    end

    local playerGrabState = gPlayerGrabStates[grabPlayerLocalIndex]

    if (playerGrabState.grabbedBy ~= nil) then
        return false
    end

    if (player_check_action_for_grab(grabPlayer, false) == false or player_check_action_for_grab(grabPlayerVictim, true) == false) then
        return false
    end

    if (player_check_moving_action_for_grab(grabPlayer, grabPlayerVictim) == false) then
        return false
    end

    if (grabPlayer.invincTimer ~= 0 or grabPlayerVictim.invincTimer ~= 0) then
        return false
    end

    if (grabPlayerVictim.health <= 0xFF) then
        return 0
    end

    local grabPlayerVictimBT = lag_compensation_get_local_state(gNetworkPlayers[grabPlayerVictimLocalIndex])
    if (grabPlayerVictimBT ~= nil and player_get_dist_squared(grabPlayer, grabPlayerVictimBT) >= (500.0 ^ 2.0)) then
        return false
    end

    return true
end

local function check_grab_request_response(grabPlayer, grabPlayerVictim)
    local grabPlayerLocalIndex = grabPlayer.playerIndex
    local grabPlayerVictimLocalIndex = grabPlayerVictim.playerIndex

    if (player_is_grabbing(grabPlayerVictimLocalIndex) ~= false) then
        return false
    end

    if (is_player_active(grabPlayerVictim) == 0) then
        return false
    end

    if (player_check_same_team(grabPlayer, grabPlayerVictim) ~= false) then
        return false
    end

    local playerGrabState = gPlayerGrabStates[grabPlayerLocalIndex]

    if (playerGrabState.grabbedBy ~= nil) then
        return false
    end

    if (player_check_action_for_grab(grabPlayer, false) == false or player_check_action_for_grab(grabPlayerVictim, true) == false) then
        return false
    end

    if (player_check_moving_action_for_grab(grabPlayer, grabPlayerVictim) == false) then
        return false
    end

    if (grabPlayer.invincTimer ~= 0 or grabPlayerVictim.invincTimer ~= 0) then
        return false
    end

    if (grabPlayerVictim.health <= 0xFF) then
        return 0
    end

    return true
end

-- request - sent to the grab target to make sure the grab target is in a position to be grabbed.
-- establishes a partial grab link and sends back a successful request response if it succeeds.
local function on_recv_grab_request(dataTable)
    if (packet_check_receive_ids(dataTable) == false) then
        return
    end

    local grabPlayerLocalIndex = network_local_index_from_global(dataTable.sendGlobalId)
    local grabPlayerVictimLocalIndex = network_local_index_from_global(dataTable.recvGlobalId)

    if (grabPlayerVictimLocalIndex ~= 0) then
        return
    end

    if (grabPlayerLocalIndex == grabPlayerVictimLocalIndex) then
        return
    end

    local grabPlayer = gMarioStates[grabPlayerLocalIndex]
    local grabPlayerVictim = gMarioStates[grabPlayerVictimLocalIndex]

    local playerGrabState = gPlayerGrabStates[grabPlayerLocalIndex]

    local responseType

    if (check_grab_request(grabPlayer, grabPlayerVictim) ~= false) then
        player_set_grabbed_data_from_request(grabPlayer, grabPlayerVictim)
        playerGrabState.grabRequestSuccess = true
        responseType = 1
    else
        playerGrabState.grabRequestSuccess = false
        responseType = 0
    end

    send_grab_request_response(grabPlayerLocalIndex, grabPlayerVictimLocalIndex, responseType)
end

function send_grab_request_response(attackerIndex, victimIndex, responseType)
    if (victimIndex ~= 0) then
        return
    end

    local attackerGlobalId = network_global_index_from_local(attackerIndex)
    local victimGlobalId = network_global_index_from_local(victimIndex)

    local dataTable = { packetId = PACKET_GRAB_REQUEST_RESPONSE,
                        sendGlobalId = victimGlobalId,
                        recvGlobalId = attackerGlobalId,
                        responseType = responseType }

    network_send(true, dataTable)
end

-- request response - performs checks one more time on the grabber's end to finalize the grab link
local function on_recv_grab_request_response(dataTable)
    if (packet_check_receive_ids(dataTable) == false) then
        return
    end

    local grabPlayerLocalIndex = network_local_index_from_global(dataTable.recvGlobalId)
    local grabPlayerVictimLocalIndex = network_local_index_from_global(dataTable.sendGlobalId)

    if (grabPlayerLocalIndex ~= 0) then
        return
    end

    if (grabPlayerLocalIndex == grabPlayerVictimLocalIndex) then
        return
    end

    local grabPlayer = gMarioStates[grabPlayerLocalIndex]
    local grabPlayerVictim = gMarioStates[grabPlayerVictimLocalIndex]

    local playerGrabStateVictim = gPlayerGrabStates[grabPlayerVictimLocalIndex]

    if (playerGrabStateVictim.sentGrabRequest ~= false) then
        playerGrabStateVictim.sentGrabRequest = false
    end

    if (dataTable.responseType == 0) then
        return
    end

    if (check_grab_request_response(grabPlayer, grabPlayerVictim) == false) then
        send_grab_release(GRAB_RELEASE_TYPE_DROP, grabPlayerLocalIndex, grabPlayerVictimLocalIndex, false, nil)
        return
    end

    player_set_grabbed_data_from_request(grabPlayer, grabPlayerVictim)
end

function send_grab_release(releaseType, attackerIndex, victimIndex, sendFaceAngle, extraData)
    if (attackerIndex ~= 0 and victimIndex ~= 0) then
        return
    end

    local attackerGlobalId = network_global_index_from_local(attackerIndex)
    local victimGlobalId = network_global_index_from_local(victimIndex)

    local dataTable = { packetId = PACKET_GRAB_RELEASE,
                        sendGlobalId = attackerGlobalId,
                        recvGlobalId = victimGlobalId,
                        releaseType = releaseType }

    if (sendFaceAngle ~= false) then
        dataTable.faceAngleYaw = gMarioStates[attackerIndex].faceAngle.y
    end

    if (extraData ~= nil) then
        dataTable.extraData = extraData
    end

    network_send(true, dataTable)
end

local function on_recv_grab_release(dataTable)
    if (packet_check_receive_ids(dataTable) == false) then
        return
    end

    local senderIndex = network_local_index_from_global(dataTable.sendGlobalId)
    local recvIndex = network_local_index_from_global(dataTable.recvGlobalId)

    local grabPlayer = gMarioStates[senderIndex]

    if (gPlayerGrabStates[recvIndex].grabbedBy ~= grabPlayer) then
        return
    end

    player_end_grab(dataTable.releaseType, gMarioStates[recvIndex], dataTable.faceAngleYaw, dataTable.extraData)
end

function send_grab_hold(attackerIndex, victimIndex)
    if (victimIndex ~= 0) then
        return
    end

    local attackerGlobalId = network_global_index_from_local(attackerIndex)
    local victimGlobalId = network_global_index_from_local(victimIndex)

    local dataTable = { packetId = PACKET_GRAB_HOLD,
                        sendGlobalId = victimGlobalId,
                        recvGlobalId = attackerGlobalId }

    network_send(true, dataTable)
end

local function on_recv_grab_hold(dataTable)
    if (packet_check_receive_ids(dataTable) == false) then
        return
    end

    local senderIndex = network_local_index_from_global(dataTable.sendGlobalId)
    local recvIndex = network_local_index_from_global(dataTable.recvGlobalId)

    if (recvIndex ~= 0) then
        return
    end

    if (player_is_grabbing(recvIndex) == false) then
        return
    end

    if (player_is_grabbing_id(recvIndex, senderIndex) == false) then
        return
    end

    local senderMarioState = gMarioStates[senderIndex]
    if (is_player_active(senderMarioState) == 0) then
        return
    end

    local recvMarioState = gMarioStates[recvIndex]

    if (act_is_player_hold_action(recvMarioState.action) ~= false) then
        mario_drop_held_object(recvMarioState)
    end

    local actionGroup = recvMarioState.action & ACT_GROUP_MASK
    if (actionGroup == ACT_GROUP_CUTSCENE or actionGroup == ACT_GROUP_AUTOMATIC) then
        send_grab_release(GRAB_RELEASE_TYPE_NONE, recvIndex, senderIndex, true, nil)
        return
    end

    act_player_set_hold_action(recvMarioState)
end

local function get_grab_state_sync_data_table(index, sequence)
    local globalIndex = network_global_index_from_local(index)

    local grabbingIdBits = player_get_grabbing_ids(index)

    local playerGrabState = gPlayerGrabStates[index]
    local grabbedById

    if (playerGrabState.grabbedBy ~= nil) then
        grabbedById = network_global_index_from_local(playerGrabState.grabbedBy.playerIndex)
    else
        grabbedById = -1
    end

    local dataTable = { packetId = PACKET_GRAB_STATE_SYNC,
                        globalIndex = globalIndex,
                        grabbingIdBits = grabbingIdBits,
                        grabbedById = grabbedById,
                        sequence = sequence }

    return dataTable
end

function send_grab_state_sync(index, reliable)
    sGrabStateSyncTimer = (30 * 2)
    local sequence = sGrabStateSyncSequence + 1
    sGrabStateSyncSequence = sequence

    network_send(reliable, get_grab_state_sync_data_table(index, sequence))
end

function send_grab_state_sync_to(localIndex, recvIndex)
    local sequence = sGrabStateSyncSequence + 1
    sGrabStateSyncSequence = sequence

    network_send_to(recvIndex, true, get_grab_state_sync_data_table(localIndex, sequence))
end

local function on_recv_grab_state_sync(dataTable)
    if (packet_check_receive_id(dataTable) == false) then
        return
    end

    local index = network_local_index_from_global(dataTable.globalIndex)
    local playerGrabState = gPlayerGrabStates[index]

    local sequence = dataTable.sequence

    if (sequence <= playerGrabState.syncSeq) then
        return
    end

    player_set_grabbing_ids(index, dataTable.grabbingIdBits)

    local grabbedById = dataTable.grabbedById

    if (grabbedById ~= -1) then
        playerGrabState.grabbedBy = gMarioStates[network_local_index_from_global(grabbedById)]
    else
        playerGrabState.grabbedBy = nil
    end

    playerGrabState.syncSeq = sequence
end

local packetCallbacks = {
    [PACKET_GRAB_REQUEST]          = on_recv_grab_request,
    [PACKET_GRAB_REQUEST_RESPONSE] = on_recv_grab_request_response,
    [PACKET_GRAB_RELEASE]          = on_recv_grab_release,
    [PACKET_GRAB_HOLD]             = on_recv_grab_hold,
    [PACKET_GRAB_STATE_SYNC]       = on_recv_grab_state_sync
}

local function on_packet_recv(dataTable)
    if (gServerSettings.playerInteractions == PLAYER_INTERACTIONS_NONE) then
        return
    end

    local packetId = dataTable.packetId

    if (packetCallbacks[packetId] ~= nil) then
        packetCallbacks[packetId](dataTable)
    end
end

hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_recv)
hook_event(HOOK_UPDATE, packet_update)