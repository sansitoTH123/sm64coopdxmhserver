-- gp_player.lua - created by Marioiscool246 on 1/11/2024, last updated on 10/26/2024 MM/DD/YY

local GRAB_INCOMPLETE_LINK_TIMEOUT = (2 * 30)

---@param marioState MarioState
---@param marioStateGrabber MarioState
local function player_grab_release_none(marioState, marioStateGrabber, faceAngleYaw, extraData)
    if (marioState.playerIndex ~= 0 or marioState.action ~= ACT_CUSTOM_BEING_GRABBED) then
        return
    end

    if (faceAngleYaw ~= nil) then
        marioState.faceAngle.y = faceAngleYaw
    end

    act_player_set_idle_action(marioState)
end

---@param marioState MarioState
---@param marioStateGrabber MarioState
local function player_grab_release_drop(marioState, marioStateGrabber, faceAngleYaw, extraData)
    if (marioState.playerIndex ~= 0) then
        return
    end

    vec3f_set(marioState.vel, 0.0, 0.0, 0.0)
    marioState.forwardVel = 0.0

    if (faceAngleYaw ~= nil) then
        marioState.faceAngle.y = faceAngleYaw
    end

    act_player_set_idle_action(marioState)
end

---@param marioState MarioState
---@param marioStateGrabber MarioState
local function player_grab_release_throw(marioState, marioStateGrabber, faceAngleYaw, extraData)
    if (marioState.playerIndex ~= 0) then
        return
    end

    vec3f_set(marioState.vel, 0.0, 0.0, 0.0)

    local forwardVel

    if (marioStateGrabber ~= nil) then
        if (extraData ~= nil and (extraData & 1) ~= 0) then
            -- get angleVel from extraData and cast to unsigned 16 bit
            local angleVel = (extraData >> 16) & 0xFFFF

            -- sign extend to 64 bits
            if ((angleVel & 0x8000) ~= 0) then
                angleVel = angleVel | 0xFFFFFFFFFFFF0000
            end

            local swingVel = player_get_bowser_swing_percent(angleVel) * 100.0

            forwardVel = 16.0

            if (forwardVel < swingVel) then
                forwardVel = swingVel
            end
        else
            forwardVel = 56.0

            local grabberHasMetalCap = (marioStateGrabber.flags & MARIO_METAL_CAP) ~= 0
            local grabbedHasMetalCap = (marioState.flags & MARIO_METAL_CAP) ~= 0

            if (grabberHasMetalCap ~= false and grabbedHasMetalCap == false) then
                forwardVel = forwardVel * 1.25
            elseif (grabberHasMetalCap == false and grabbedHasMetalCap ~= false) then
                forwardVel = forwardVel * 0.75
            end

            forwardVel = forwardVel + marioStateGrabber.forwardVel
            vec3f_add(marioState.vel, marioStateGrabber.vel)
        end
    else
        forwardVel = 56.0
    end

    forwardVel = forwardVel * gGlobalSyncTable.grabThrowMult

    local upwardsVel = forwardVel * 0.625

    marioState.forwardVel = forwardVel
    marioState.vel.y = marioState.vel.y + upwardsVel

    if (faceAngleYaw ~= nil) then
        marioState.faceAngle.y = faceAngleYaw
    end

    set_mario_action(marioState, ACT_THROWN_FORWARD, 0)
end

---@param marioState MarioState
---@param marioStateGrabber MarioState
local function player_grab_release_knockback(marioState, marioStateGrabber, faceAngleYaw, extraData)
    if (marioState.playerIndex ~= 0) then
        return
    end

    vec3f_set(marioState.vel, 0.0, 0.0, 0.0)

    local forwardVel = 16.0
    local upwardsVel = forwardVel * 0.625

    marioState.forwardVel = forwardVel
    marioState.vel.y = marioState.vel.y + upwardsVel

    if (faceAngleYaw ~= nil) then
        marioState.faceAngle.y = faceAngleYaw
    end

    set_mario_action(marioState, ACT_FORWARD_AIR_KB, 0)
end

---@param marioState MarioState
---@param marioStateGrabber MarioState
local function player_grab_release_escape(marioState, marioStateGrabber, faceAngleYaw, extraData)
    if (marioState.playerIndex == 0) then
        if (faceAngleYaw ~= nil) then
            marioState.faceAngle.y = faceAngleYaw
        end

        marioState.forwardVel = 0.0
        set_mario_action(marioState, ACT_JUMP, 0);
        marioState.flags = marioState.flags & ~MARIO_UNKNOWN_08

        marioState.forwardVel = 15.0 * 1.25 -- forwardVel is multiplied by 0.8 by ACT_JUMP
        vec3f_set(marioState.vel, 0.0, 42.0, 0.0)

        if (marioStateGrabber ~= nil) then
            marioState.forwardVel = marioState.forwardVel + (marioStateGrabber.forwardVel * 1.25)
            vec3f_add(marioState.vel, marioStateGrabber.vel)
        end
    elseif (marioStateGrabber ~= nil and marioStateGrabber.playerIndex == 0) then
        set_mario_action(marioStateGrabber, ACT_BACKWARD_AIR_KB, 0)
    end
end

local sPlayerGrabReleaseFuncs = {[GRAB_RELEASE_TYPE_NONE] = player_grab_release_none,
                                 [GRAB_RELEASE_TYPE_DROP] = player_grab_release_drop,
                                 [GRAB_RELEASE_TYPE_THROW] = player_grab_release_throw,
                                 [GRAB_RELEASE_TYPE_KNOCKBACK] = player_grab_release_knockback,
                                 [GRAB_RELEASE_TYPE_ESCAPE] = player_grab_release_escape}

---@param marioStateAttacker MarioState
---@param marioStateVictim MarioState
function player_set_grabbed_data_from_request(marioStateAttacker, marioStateVictim)
    if (marioStateAttacker == nil or marioStateVictim == nil) then
        return
    end

    local attackerIndex = marioStateAttacker.playerIndex
    local victimIndex = marioStateVictim.playerIndex

    if (victimIndex == 0) then
        local victimGrabState = gPlayerGrabStates[victimIndex]
        victimGrabState.grabbedBy = marioStateAttacker
        send_grab_state_sync(victimIndex, true)
    elseif (attackerIndex == 0) then
        player_set_grabbing_id(attackerIndex, victimIndex)
        send_grab_state_sync(attackerIndex, true)
    end
end

---@param marioStateAttacker MarioState
---@param marioStateVictim MarioState
function player_start_grab(marioStateAttacker, marioStateVictim)
    if (marioStateAttacker == nil or marioStateVictim == nil) then
        return
    end

    local victimIndex = marioStateVictim.playerIndex

    if (victimIndex ~= 0) then
        return
    end

    local victimGrabState = gPlayerGrabStates[victimIndex]

    if (victimGrabState.grabbedBy == nil) then
        return
    end

    if (marioStateVictim.action == ACT_CUSTOM_BEING_GRABBED) then
        return
    end

    drop_and_set_mario_action(marioStateVictim, ACT_CUSTOM_BEING_GRABBED, 0)
    send_grab_hold(marioStateAttacker.playerIndex, victimIndex)

    local camera = marioStateVictim.area.camera
    if (camera ~= nil and camera.mode == CAMERA_MODE_WATER_SURFACE) then
        set_camera_mode(marioStateVictim.area.camera, marioStateVictim.area.camera.defMode, 1)
    end
end

---@param marioStateVictim MarioState
function player_end_grab(releaseType, marioStateVictim, faceAngleYaw, extraData)
    if (marioStateVictim == nil) then
        return
    end

    local victimIndex = marioStateVictim.playerIndex
    local victimGrabState = gPlayerGrabStates[victimIndex]
    local victimGrabbedBy = victimGrabState.grabbedBy

    if (victimGrabbedBy ~= nil) then
        local grabbedByIndex = victimGrabbedBy.playerIndex

        if (victimIndex == 0) then
            gPlayerGrabStates[grabbedByIndex].grabRequestSuccess = false
            send_grab_release(releaseType, grabbedByIndex, victimIndex, true, extraData)
            victimGrabState.grabbedBy = nil
            send_grab_state_sync(victimIndex, true)
        elseif (grabbedByIndex == 0) then
            player_clear_grabbing_id(grabbedByIndex, victimIndex)
            send_grab_state_sync(grabbedByIndex, true)

            if (player_is_grabbing(grabbedByIndex) ~= false) then
                return
            end

            if (act_is_player_hold_action(victimGrabbedBy.action) ~= false) then
                act_player_set_idle_action(victimGrabbedBy)
            end
        end
    end

    if (sPlayerGrabReleaseFuncs[releaseType] ~= nil) then
        sPlayerGrabReleaseFuncs[releaseType](marioStateVictim, victimGrabbedBy, faceAngleYaw, extraData)
    end
end

function player_is_grabbing(playerIndex)
    return next(gPlayerGrabStates[playerIndex].grabbing) ~= nil
end

function player_is_grabbing_id(grabbingId, grabbedId)
    return gPlayerGrabStates[grabbingId].grabbing[grabbedId] ~= nil
end

function player_is_grab_link_present(playerIndex)
    local grabbingTable = gPlayerGrabStates[playerIndex].grabbing;

    for k,v in pairs(grabbingTable) do
        local grabbingState = gPlayerGrabStates[v]

        if (grabbingState.grabbedBy ~= nil and grabbingState.grabbedBy.playerIndex == playerIndex) then
            return true
        end
    end

    return false
end

function player_set_grabbing_id(grabbingId, grabbedId)
    gPlayerGrabStates[grabbingId].grabbing[grabbedId] = grabbedId
end

function player_clear_grabbing_id(grabbingId, grabbedId)
    gPlayerGrabStates[grabbingId].grabbing[grabbedId] = nil
end

function player_clear_all_grabbing_ids(playerIndex)
    local grabbingTable = gPlayerGrabStates[playerIndex].grabbing;

    for k in pairs(grabbingTable) do
        grabbingTable[k] = nil
    end
end

function player_get_grabbing_ids(playerIndex)
    local grabbingTable = gPlayerGrabStates[playerIndex].grabbing;
    local playerIdBits = 0

    for k,v in pairs(grabbingTable) do
        local globalIndex = network_global_index_from_local(v)
        playerIdBits = playerIdBits | (1 << globalIndex)
    end

    return playerIdBits
end

function player_set_grabbing_ids(playerIndex, grabbingIdBits)
    player_clear_all_grabbing_ids(playerIndex)

    for i = 0, (MAX_PLAYERS - 1) do
        if ((grabbingIdBits & (1 << i)) ~= 0) then
            local localIndex = network_local_index_from_global(i)
            player_set_grabbing_id(playerIndex, localIndex)
        end
    end
end

---@param localMarioState MarioState
function player_check_multi_grab(localMarioState)
    local localPlayerIndex = localMarioState.playerIndex

    local localGrabbedBy = gPlayerGrabStates[localPlayerIndex].grabbedBy

    if (localGrabbedBy == nil) then
        return false
    end

    -- can't grab and be grabbed
    if (localGrabbedBy ~= nil and player_is_grabbing(localPlayerIndex) ~= false) then
        return true
    end

    -- ignore if the grabbed by player is not currently grabbing anything
    if (localGrabbedBy ~= nil and player_is_grabbing(localGrabbedBy.playerIndex) == false) then
        return false
    end

    local localGlobalIndex = gNetworkPlayers[localPlayerIndex].globalIndex

    for i = 0, (MAX_PLAYERS - 1) do
        local networkPlayer = network_player_from_global_index(i)

        if (networkPlayer ~= nil) then
            local npLocalIndex = networkPlayer.localIndex

            if (networkPlayer.connected ~= false) and (npLocalIndex ~= 0) and (i < localGlobalIndex) and (localGrabbedBy == gPlayerGrabStates[npLocalIndex].grabbedBy) then
                return true
            end
        end
    end

    return false
end

---@param marioState MarioState
function player_check_action_for_grab(marioState, useAllowedInvulnActions)
    local action = marioState.action

    local actionGroup = action & ACT_GROUP_MASK
    if (actionGroup == ACT_GROUP_CUTSCENE or actionGroup == ACT_GROUP_AUTOMATIC) then
        return false
    end

    if (action == ACT_JUMP_KICK or (action == ACT_GROUND_POUND and marioState.actionState ~= 0)) then
        return false
    end

    if ((action & ACT_FLAG_THROWING) ~= 0 or action == ACT_RELEASING_BOWSER) then
        return false
    end

    if ((action & ACT_FLAG_INVULNERABLE) ~= 0 and (useAllowedInvulnActions == false or gPlayerAllowedInvulnActions[action] == nil)) then
        return false
    end

    if ((action & ACT_FLAG_INTANGIBLE) ~= 0) then
        return false
    end

    if (marioState.invincTimer > 3 or marioState.invincTimer == -1) then
        return false
    end

    if ((marioState.flags & MARIO_VANISH_CAP) ~= 0) then
        return false
    end

    return true
end

---@param marioStateAttacker MarioState
---@param marioStateVictim MarioState
function player_check_moving_action_for_grab(marioStateAttacker, marioStateVictim)
    local victimAction = marioStateVictim.action

    if (gPlayerCheckMovingActionForGrabActions[victimAction] == nil) then
        return true
    end

    local victimVelSquared = player_get_vel_squared(marioStateVictim)

    if (victimAction == ACT_SLIDE_KICK_SLIDE or victimAction == ACT_SLIDE_KICK) then
        if (victimVelSquared < (15.0 ^ 2.0)) then
            return true
        end
    elseif (victimVelSquared < (40.0 ^ 2.0)) then
        return true
    end

    return player_get_vel_squared(marioStateAttacker) > victimVelSquared
end

function player_get_bowser_swing_percent(angleVel)
    return math.abs(angleVel) / 0x1000
end

-- Simple check with description colors since mods commonly color team descriptions differently to one another
---@param marioStateAttacker MarioState
---@param marioStateVictim MarioState
function player_check_same_team(marioStateAttacker, marioStateVictim)
    if (gGlobalSyncTable.checkSameTeam == false) then
        return false
    end

    local networkPlayerAttacker = gNetworkPlayers[marioStateAttacker.playerIndex]
    local networkPlayerVictim = gNetworkPlayers[marioStateVictim.playerIndex]

    -- treat no description or description alpha 0 as no team
    if (networkPlayerAttacker.description == '' or networkPlayerVictim.description == '' or
        networkPlayerAttacker.descriptionA == 0 or networkPlayerVictim.descriptionA == 0) then
        return false
    end

    return networkPlayerAttacker.descriptionR == networkPlayerVictim.descriptionR and
           networkPlayerAttacker.descriptionG == networkPlayerVictim.descriptionG and
           networkPlayerAttacker.descriptionB == networkPlayerVictim.descriptionB
end

-- Returns integer
-- 0: Do not start grab
-- 1: Start grab
-- 2: Do not start grab, because both players were punching
---@param marioStateAttacker MarioState
---@param marioStateVictim MarioState
local function player_interaction_can_start_grab(marioStateAttacker, marioStateVictim)
    if (marioStateVictim == nil) then
        return 0
    end

    if (gServerSettings.playerInteractions == PLAYER_INTERACTIONS_NONE) then
        return 0
    end

    if (is_player_active(marioStateVictim) == 0) then
        return 0
    end

    if (player_check_same_team(marioStateAttacker, marioStateVictim) ~= false) then
        return 0
    end

    local attackerAction = marioStateAttacker.action
    local isAttackerPunching = (attackerAction == ACT_PUNCHING or attackerAction == ACT_MOVE_PUNCHING) and (marioStateAttacker.flags & MARIO_PUNCHING) ~= 0

    if (isAttackerPunching == false) then
        return 0
    end

    local victimAction = marioStateVictim.action
    local isVictimPunching = (victimAction == ACT_PUNCHING or victimAction == ACT_MOVE_PUNCHING) and (marioStateVictim.flags & MARIO_PUNCHING) ~= 0

    if (isAttackerPunching ~= false and isVictimPunching ~= false) then
        return 2
    end

    if (marioStateAttacker.actionArg > 2) then
        return 0
    end

    if (player_check_action_for_grab(marioStateVictim, true) == false) then
        return 0
    end

    if (player_check_moving_action_for_grab(marioStateAttacker, marioStateVictim) == false) then
        return 0
    end

    if (marioStateAttacker.invincTimer ~= 0 or marioStateVictim.invincTimer ~= 0) then
        return 0
    end

    if (marioStateVictim.health <= 0xFF) then
        return 0
    end

    local attackerIndex = marioStateAttacker.playerIndex
    local victimIndex = marioStateVictim.playerIndex

    local isGrabbingPlayer = player_is_grabbing(attackerIndex) ~= false or player_is_grabbing(victimIndex) ~= false

    if (isGrabbingPlayer ~= false) then
        return 0
    end

    local attackerGrabState = gPlayerGrabStates[attackerIndex]
    local victimGrabState = gPlayerGrabStates[victimIndex]

    local isGrabbedByPlayer = attackerGrabState.grabbedBy ~= nil or victimGrabState.grabbedBy ~= nil

    if (isGrabbedByPlayer ~= false) then
        return 0
    end

    return 1
end

---@param marioState1 MarioState
---@param marioState2 MarioState
function player_get_dist_squared(marioState1, marioState2)
    x = marioState1.pos.x - marioState2.pos.x
    y = marioState1.pos.y - marioState2.pos.y
    z = marioState1.pos.z - marioState2.pos.z

    return x * x + y * y + z * z
end

---@param marioState MarioState
function player_get_vel_squared(marioState)
    local velX = marioState.vel.x
    local velY = marioState.vel.y
    local velZ = marioState.vel.z

    return velX * velX + velY * velY + velZ * velZ
end

---@param marioState MarioState
local function player_update(marioState)
    local playerIndex = marioState.playerIndex

    local action = marioState.action

    local playerGrabState = gPlayerGrabStates[playerIndex]

    if (playerGrabState.sentGrabRequestTimeout > 0) then
        playerGrabState.sentGrabRequestTimeout = playerGrabState.sentGrabRequestTimeout - 1
    elseif (playerGrabState.sentGrabRequest ~= false) then
        playerGrabState.sentGrabRequest = false
    end

    if (playerIndex ~= 0) then
        return
    end

    if (marioState.action == ACT_PICKING_UP_BOWSER or marioState.action == ACT_HOLDING_BOWSER) then
        gPlayerGrabStates[playerIndex].throwAngleVelY = marioState.angleVel.y
    end

    local grabbedByPlayer = playerGrabState.grabbedBy

    -- check for a complete grab link to start a grab
    if (grabbedByPlayer ~= nil) then
        if (marioState.action == ACT_CUSTOM_BEING_GRABBED) then
            return
        end

        local grabbedByIndex = grabbedByPlayer.playerIndex

        local grabbedByState = gPlayerGrabStates[grabbedByIndex]

        if (player_is_grabbing_id(grabbedByIndex, playerIndex) == false) then
            playerGrabState.incompleteLinkTimer = playerGrabState.incompleteLinkTimer + 1
        end

        -- is there a incomplete grab link for too long?
        if (playerGrabState.incompleteLinkTimer >= GRAB_INCOMPLETE_LINK_TIMEOUT) then
            playerGrabState.incompleteLinkTimer = 0
            playerGrabState.grabbedBy = nil
            send_grab_state_sync(playerIndex, true)
            return
        end

        if (grabbedByState.grabRequestSuccess == false) then
            return
        end

        grabbedByState.grabRequestSuccess = false

        player_start_grab(grabbedByPlayer, marioState)
        return
    end

    if (player_is_grabbing(playerIndex) ~= false) then
        if (player_is_grab_link_present(playerIndex) == false) then
            playerGrabState.incompleteLinkTimer = playerGrabState.incompleteLinkTimer + 1
        end

        local grabbingTable = playerGrabState.grabbing

        -- is there a incomplete grab link for too long?
        if (playerGrabState.incompleteLinkTimer >= GRAB_INCOMPLETE_LINK_TIMEOUT) then
            if (act_is_player_hold_action(action) ~= false) then
                act_player_set_idle_action(marioState)
            else
                for k,v in pairs(grabbingTable) do
                    send_grab_release(GRAB_RELEASE_TYPE_NONE, playerIndex, v, true, nil)
                    player_clear_grabbing_id(playerIndex, v)
                end

                send_grab_state_sync(playerIndex, true)
            end

            playerGrabState.incompleteLinkTimer = 0
            return
        end

        -- determine when to throw the grabbed player
        if (act_player_is_throwing(marioState)) then
            local extraData

            if (action == ACT_RELEASING_BOWSER) then
                extraData = (gPlayerGrabStates[playerIndex].throwAngleVelY << 16) & 0xFFFF0000
                extraData = extraData | 1
            end

            for k,v in pairs(grabbingTable) do
                send_grab_release(GRAB_RELEASE_TYPE_THROW, playerIndex, v, true, extraData)
                player_clear_grabbing_id(playerIndex, v)
            end

            send_grab_state_sync(playerIndex, true)
        end

        if (action == ACT_HOLDING_BOWSER) then
            marioState.actionTimer = 0
        end

        if (((marioState.controller.buttonDown & X_BUTTON) ~= 0 and (marioState.controller.buttonPressed & L_TRIG) ~= 0) or
            ((marioState.controller.buttonDown & L_TRIG) ~= 0 and (marioState.controller.buttonPressed & X_BUTTON) ~= 0)) then
            act_player_swap_hold_action(marioState)
        end
    end
end

---@param marioState MarioState
---@param object Object
local function player_allow_interact(marioState, object, intType)
    local playerIndex = marioState.playerIndex

    if (playerIndex ~= 0) then
        return true
    end

    -- main grab detection
    -- this is done at the interact level not the pvp interact level so it allows custom checks and hopefully maintains compatibility with pvp based mods
    if (intType ~= INTERACT_PLAYER) then
        return true
    end

    -- are we actually a player
    if (get_id_from_behavior(object.behavior) ~= id_bhvMario) then
        return true
    end

    local objectPlayerIndex = object.oBehParams - 1

    if (objectPlayerIndex >= MAX_PLAYERS or objectPlayerIndex <= 0) then
        return true
    end

    local objectMarioState = gMarioStates[objectPlayerIndex]

    if (objectMarioState.marioObj ~= object) then
        return true
    end

    local canStartGrabResult = player_interaction_can_start_grab(marioState, objectMarioState)

    if (canStartGrabResult == 0) then
        return true
    end

    if (canStartGrabResult == 1) then
        send_grab_request(marioState.playerIndex, objectPlayerIndex)
    elseif (canStartGrabResult == 2) then
        set_mario_particle_flags(marioState, PARTICLE_TRIANGLE, 0)
        set_mario_particle_flags(objectMarioState, PARTICLE_TRIANGLE, 0)
    end

    return false
end

---@param marioState MarioState
---@param object Object
local function player_on_interact(marioState, object, intType, isInteracted)
    local playerIndex = marioState.playerIndex

    if (playerIndex ~= 0) then
        return
    end

    -- cancel grab on vanish cap interaction
    if (intType ~= INTERACT_CAP and isInteracted == false) then
        return
    end

    if (get_id_from_behavior(object.behavior) ~= id_bhvVanishCap) then
        return
    end

    if (player_is_grabbing(playerIndex) == false) then
        return
    end

    local grabbingTable = gPlayerGrabStates[playerIndex].grabbing
    for k,v in pairs(grabbingTable) do
        send_grab_release(GRAB_RELEASE_TYPE_DROP, playerIndex, v, true, nil)
        player_clear_grabbing_id(playerIndex, v)
    end

    send_grab_state_sync(playerIndex, true)
end

---@param marioStateAttacker MarioState
---@param marioStateVictim MarioState
local function player_allow_pvp_attack(marioStateAttacker, marioStateVictim)
    local attackerIndex = marioStateAttacker.playerIndex
    local victimIndex = marioStateVictim.playerIndex

    if (gPlayerGrabStates[attackerIndex].grabbedBy ~= nil or gPlayerGrabStates[victimIndex].grabbedBy ~= nil) then
        return false
    end

    if (player_is_grabbing(attackerIndex) ~= false) then
        return false
    end

    local attackerAction = marioStateAttacker.action

    if (player_is_grabbing(victimIndex) ~= false) then
        return gGlobalSyncTable.groundPoundsBreaksGrabs ~= false and attackerAction == ACT_GROUND_POUND and marioStateAttacker.actionState ~= 0
    end

    local isAttackerPunching = (attackerAction == ACT_PUNCHING or attackerAction == ACT_MOVE_PUNCHING) and (marioStateAttacker.flags & MARIO_PUNCHING) ~= 0
    if (isAttackerPunching ~= false) then
        return false
    end

    return true
end

local function player_on_warp_and_level_init()
    player_end_grab(GRAB_RELEASE_TYPE_NONE, gMarioStates[0], nil, nil)
end

---@param marioState MarioState
local function player_on_connected(marioState)
    local playerIndex = marioState.playerIndex

    if (playerIndex ~= 0) then
        send_grab_state_sync_to(0, playerIndex)
    end
end

---@param marioState MarioState
local function player_on_disconnected(marioState)
    local playerIndex = marioState.playerIndex
    local playerGrabbedBy = gPlayerGrabStates[playerIndex].grabbedBy

    if (playerGrabbedBy ~= nil) then
        local playerGrabbedByIndex = playerGrabbedBy.playerIndex

        if (playerGrabbedByIndex == 0) then
            if (act_is_player_hold_action(playerGrabbedBy.action) ~= false) then
                act_player_set_idle_action(playerGrabbedBy)
            end

            player_clear_all_grabbing_ids(playerGrabbedByIndex)
            send_grab_state_sync(playerGrabbedByIndex, true)
        end
    end

    player_grab_state_reset(playerIndex)
end

hook_event(HOOK_MARIO_UPDATE, player_update)
hook_event(HOOK_ALLOW_INTERACT, player_allow_interact)
hook_event(HOOK_ON_INTERACT, player_on_interact)
hook_event(HOOK_ALLOW_PVP_ATTACK, player_allow_pvp_attack)
hook_event(HOOK_ON_WARP, player_on_warp_and_level_init)
hook_event(HOOK_ON_LEVEL_INIT, player_on_warp_and_level_init)
hook_event(HOOK_ON_PLAYER_CONNECTED, player_on_connected)
hook_event(HOOK_ON_PLAYER_DISCONNECTED, player_on_disconnected)