-- gp_player_actions.lua - created by Marioiscool246 on 1/14/2024, last updated on 10/26/2024 MM/DD/YY

ACT_CUSTOM_BEING_GRABBED = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_STATIONARY | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE | ACT_FLAG_PAUSE_EXIT)

local PLAYER_MASHOUT_MAX = 120

local function lerp(a, b, t)
    return a * (1.0 - t) + (b * t)
end

---@param marioState MarioState
local function act_player_get_mashout_timer(marioState)
    local mashoutTimer = marioState.actionState & 0xFF
    return mashoutTimer
end

---@param marioState MarioState
local function act_player_set_mashout_timer(marioState, mashoutTimer)
    if (mashoutTimer > 0xFF) then
        mashoutTimer = 0xFF
    end

    marioState.actionState = marioState.actionState & 0xFF00
    marioState.actionState = marioState.actionState | mashoutTimer
end

---@param marioState MarioState
local function act_player_get_mashout_debounce(marioState)
    local mashoutDebounce = (marioState.actionState & 0xFF00) >> 8
    return mashoutDebounce
end

---@param marioState MarioState
local function act_player_set_mashout_debounce(marioState, mashoutDebounce)
    if (mashoutDebounce > 0xFF) then
        mashoutDebounce = 0xFF
    end

    marioState.actionState = marioState.actionState & 0xFF
    marioState.actionState = marioState.actionState | (mashoutDebounce << 8)
end

---@param marioState MarioState
local function act_player_update_mashout_timer(marioState, marioStateGrabber)
    if (marioState.playerIndex ~= 0) then
        return
    end

    local mashoutTimer = act_player_get_mashout_timer(marioState)

    if (gGlobalSyncTable.mashoutEnabled == false) then
        if (mashoutTimer ~= 0) then
            mashoutTimer = 0
            act_player_set_mashout_timer(marioState, mashoutTimer)
        end
        return
    end

    if (act_player_get_mashout_debounce(marioState) ~= 0) then
        return
    end

    if ((marioState.controller.buttonPressed & A_BUTTON) ~= 0) then
        -- if a player has a metal cap, give them an advantage unless both or neither have a metal cap
        local grabberHasMetalCap = (marioStateGrabber.flags & MARIO_METAL_CAP) ~= 0
        local grabbedHasMetalCap = (marioState.flags & MARIO_METAL_CAP) ~= 0

        local mashoutAddAmount = 9

        if (grabberHasMetalCap ~= false and grabbedHasMetalCap == false) then
            mashoutAddAmount = mashoutAddAmount * 0.75
        elseif (grabberHasMetalCap == false and grabbedHasMetalCap ~= false) then
            mashoutAddAmount = mashoutAddAmount * 1.25
        end

        -- grabbers with bowser swing are harder to escape from if they're swinging faster
        local grabberAction = marioStateGrabber.action
        if (grabberAction == ACT_HOLDING_BOWSER or grabberAction == ACT_RELEASING_BOWSER) then
            local multMaxPercent = 0.7
            local bowserSwingMashoutMult = lerp(0.8, multMaxPercent, player_get_bowser_swing_percent(marioStateGrabber.angleVel.y))

            if (bowserSwingMashoutMult < multMaxPercent) then
                bowserSwingMashoutMult = multMaxPercent
            end

            mashoutAddAmount = mashoutAddAmount * bowserSwingMashoutMult
        end

        -- round up
        mashoutAddAmount = math.floor(mashoutAddAmount + 0.5)

        mashoutTimer = mashoutTimer + mashoutAddAmount

        if (mashoutTimer > PLAYER_MASHOUT_MAX) then
            mashoutTimer = PLAYER_MASHOUT_MAX
        end

        act_player_set_mashout_debounce(marioState, 3)
    elseif (mashoutTimer > 0) then
        mashoutTimer = mashoutTimer - 2

        if (mashoutTimer < 0) then
            mashoutTimer = 0
        end
    end

    act_player_set_mashout_timer(marioState, mashoutTimer)
end

---@param marioState MarioState
local function act_player_update_mashout_debounce(marioState)
    local mashoutDebounce = act_player_get_mashout_debounce(marioState)

    if (gGlobalSyncTable.mashoutEnabled == false) then
        if (mashoutDebounce ~= 0) then
            mashoutDebounce = 0
            act_player_set_mashout_debounce(marioState, mashoutDebounce)
        end
        return
    end

    mashoutDebounce = mashoutDebounce - 1

    if (mashoutDebounce < 0) then
        mashoutDebounce = 0
    end

    act_player_set_mashout_debounce(marioState, mashoutDebounce)
end

---@param marioState MarioState
function act_custom_being_grabbed(marioState)
    local playerIndex = marioState.playerIndex
    local grabbedByPlayer = gPlayerGrabStates[playerIndex].grabbedBy

    if (playerIndex == 0) then
        if (is_player_active(grabbedByPlayer) == 0 or
            player_check_multi_grab(marioState) == true or
            marioState.actionTimer >= (30 * 2)) then

            player_end_grab(GRAB_RELEASE_TYPE_DROP, marioState, nil, nil)
            return 0
        end

        if (act_player_get_mashout_timer(marioState) >= PLAYER_MASHOUT_MAX) then
            player_end_grab(GRAB_RELEASE_TYPE_ESCAPE, marioState, nil, nil)
            return 0
        end
    end

    local grabAnimation

    marioState.marioObj.oIntangibleTimer = 5

    local grabbedCharacter = get_character(marioState)

    local animOffsetEnabled = grabbedCharacter.animOffsetEnabled ~= 0

    if (grabbedByPlayer ~= nil and (act_is_player_hold_action(grabbedByPlayer.action) ~= false or act_player_is_starting_throw(grabbedByPlayer) ~= false)) then
        vec3f_copy(marioState.pos, grabbedByPlayer.pos)
        vec3s_copy(marioState.faceAngle, grabbedByPlayer.faceAngle)

        local beingSwungFast = grabbedByPlayer.action == ACT_HOLDING_BOWSER and math.abs(grabbedByPlayer.angleVel.y) > 0xE00

        if (beingSwungFast) then
            grabAnimation = CHAR_ANIM_AIRBORNE_ON_STOMACH
        else
            grabAnimation = CHAR_ANIM_BEING_GRABBED
        end

        if (marioState.marioBodyState.updateTorsoTime == gMarioStates[0].marioBodyState.updateTorsoTime) then
            local gfxPos = {x = get_hand_foot_pos_x(grabbedByPlayer, 0),
                            y = get_hand_foot_pos_y(grabbedByPlayer, 0),
                            z = get_hand_foot_pos_z(grabbedByPlayer, 0)}

            local heldPlayerOffsetX = 50

            gfxPos.x = gfxPos.x + sins(marioState.faceAngle.y) * heldPlayerOffsetX
            gfxPos.z = gfxPos.z + coss(marioState.faceAngle.y) * heldPlayerOffsetX

            if ((grabbedByPlayer.action & ACT_FLAG_THROWING) == 0) then
                local heldPlayerOffsetZ = gPlayerCharacterHoldZOffsets[get_character(grabbedByPlayer).type]

                if (heldPlayerOffsetZ == nil) then
                    heldPlayerOffsetZ = 20
                end

                if (grabbedByPlayer.action == ACT_PICKING_UP_BOWSER or grabbedByPlayer.action == ACT_HOLDING_BOWSER) then
                    heldPlayerOffsetZ = heldPlayerOffsetZ - 10
                end

                gfxPos.x = gfxPos.x + coss(marioState.faceAngle.y) * heldPlayerOffsetZ
                gfxPos.z = gfxPos.z + -sins(marioState.faceAngle.y) * heldPlayerOffsetZ

                -- toad looks too awkward when being swung fast. move him up a bit.
                if (grabbedCharacter.type == CT_TOAD and beingSwungFast) then
                    gfxPos.y = gfxPos.y + 20
                end
            end

            vec3f_copy(marioState.marioObj.header.gfx.pos, gfxPos)

            if (animOffsetEnabled ~= false) then
                gPlayerGrabStates[playerIndex].holdPosY = gfxPos.y
            end
        else
            vec3f_copy(marioState.marioObj.header.gfx.pos, marioState.pos)

            if (animOffsetEnabled ~= false) then
                gPlayerGrabStates[playerIndex].holdPosY = marioState.pos.y
            end
        end

        vec3s_set(marioState.marioObj.header.gfx.angle, 0, marioState.faceAngle.y, 0)

        marioState.actionTimer = 0

        -- grab mashout
        act_player_update_mashout_timer(marioState, grabbedByPlayer)
        act_player_update_mashout_debounce(marioState)
    else
        grabAnimation = CHAR_ANIM_BEING_GRABBED
        marioState.actionTimer = marioState.actionTimer + 1
        marioState.actionState = 0
    end

    if (animOffsetEnabled ~= false) then
        marioState.marioObj.hookRender = 1
        marioState.marioObj.header.gfx.node.extraFlags = marioState.marioObj.header.gfx.node.extraFlags | 0x80
    end

    -- accel is fixed point
    set_character_anim_with_accel(marioState, grabAnimation, 0x10000 * ((act_player_get_mashout_timer(marioState) / (PLAYER_MASHOUT_MAX / 1.5)) + 1.0))

    return 0
end

---@param marioState MarioState
local function player_on_set_action(marioState)
    local playerIndex = marioState.playerIndex

    if (playerIndex ~= 0) then
        return
    end

    local action = marioState.action

    if (action == ACT_CUSTOM_BEING_GRABBED) then
        marioState.interactObj = nil
        marioState.usedObj = nil
        return
    end

    if (action == ACT_RELEASING_BOWSER) then
        marioState.marioBodyState.grabPos = 1
    end

    local playerGrabState = gPlayerGrabStates[playerIndex]
    local prevAction = marioState.prevAction
    local wasHolding = act_is_player_hold_action(prevAction) ~= false

    if (wasHolding ~= false) then
        playerGrabState.incompleteLinkTimer = 0
    end

    local wasThrowing = (prevAction & ACT_FLAG_THROWING) ~= 0 or prevAction == ACT_RELEASING_BOWSER

    if (player_is_grabbing(playerIndex) ~= false and
        (action & ACT_FLAG_THROWING) == 0 and
        action ~= ACT_RELEASING_BOWSER and
        act_is_player_hold_action(action) == false) and
        (wasHolding ~= false or wasThrowing ~= false) then

        local releaseType

        if (wasThrowing ~= false) then
            releaseType = GRAB_RELEASE_TYPE_THROW
        elseif (gPlayerKnockbackActions[action] ~= nil) then
            if (prevAction == ACT_HOLDING_BOWSER) then
                releaseType = GRAB_RELEASE_TYPE_THROW
            else
                releaseType = GRAB_RELEASE_TYPE_KNOCKBACK
            end
        else
            releaseType = GRAB_RELEASE_TYPE_DROP
        end

        local extraData

        if (releaseType == GRAB_RELEASE_TYPE_THROW and (prevAction == ACT_RELEASING_BOWSER or prevAction == ACT_HOLDING_BOWSER)) then
            extraData = (gPlayerGrabStates[playerIndex].throwAngleVelY << 16) & 0xFFFF0000
            extraData = extraData | 1
        end

        local grabbingTable = playerGrabState.grabbing

        for k,v in pairs(grabbingTable) do
            send_grab_release(releaseType, playerIndex, v, true, extraData)
            player_clear_grabbing_id(playerIndex, v)
        end

        send_grab_state_sync(playerIndex, true)
        return
    end

    if (playerGrabState.grabbedBy ~= nil) then
        player_end_grab(GRAB_RELEASE_TYPE_NONE, marioState, nil, nil)
    end
end

---@param object Object
local function player_on_object_render(object)
    -- hacky workaround to prevent update_character_anim_offset from setting marioObj.header.gfx.pos.y

    -- hack: for some reason, coop doesn't check to see if the object passed to smlua_call_event_hooks_object_param is really an Object instead of a GraphNodeObject
    -- so it then reads garbage from the behavior offset, leading to crashes for some objects. check for our custom flag here to hopefully prevent this.
    if ((object.header.gfx.node.extraFlags & 0x80) == 0) then
        return
    end

    object.header.gfx.node.extraFlags = object.header.gfx.node.extraFlags & ~0x80

    if (get_id_from_behavior(object.behavior) ~= id_bhvMario) then
        return
    end

    object.hookRender = 0

    local globalIndex = object.globalPlayerIndex

    if (globalIndex >= MAX_PLAYERS or globalIndex <= 0) then
        return
    end

    local localIndex = network_local_index_from_global(globalIndex)
    local marioState = gMarioStates[localIndex]

    if (marioState.marioObj ~= object) then
        return
    end

    local character = get_character(marioState)

    if (character.animOffsetEnabled == 0) then
        return
    end

    if (marioState.action ~= ACT_CUSTOM_BEING_GRABBED) then
        return
    end

    object.header.gfx.pos.y = gPlayerGrabStates[localIndex].holdPosY
end

function act_is_player_hold_action(action)
    return gPlayerHoldActions[action] ~= nil
end

---@param marioState MarioState
function act_player_is_throwing(marioState)
    local action = marioState.action

    return gPlayerThrowActionTimers[action] ~= nil and marioState.actionTimer >= gPlayerThrowActionTimers[action]
end

---@param marioState MarioState
function act_player_is_starting_throw(marioState)
    local action = marioState.action

    return gPlayerThrowActionTimers[action] ~= nil and marioState.actionTimer < gPlayerThrowActionTimers[action]
end

---@param marioState MarioState
function act_player_set_idle_action(marioState)
    if ((marioState.action) & ACT_FLAG_STATIONARY) ~= 0 then
        set_mario_action(marioState, ACT_IDLE, 0)
    elseif ((marioState.action) & ACT_FLAG_MOVING) ~= 0 then
        if ((marioState.action) & ACT_FLAG_SWIMMING) ~= 0 then
            set_mario_action(marioState, ACT_WATER_IDLE, 0)
        else
            set_mario_action(marioState, ACT_WALKING, 0)
        end
    elseif ((marioState.action) & ACT_FLAG_AIR) ~= 0 then
        set_mario_action(marioState, ACT_FREEFALL, 0)
    else
        if (marioState.pos.y <= (marioState.waterLevel - 100)) then
            set_mario_action(marioState, ACT_WATER_IDLE, 0)
        else
            set_mario_action(marioState, ACT_FREEFALL, 0)
        end
    end
end

---@param marioState MarioState
function act_player_set_hold_action(marioState)
    if (act_is_player_hold_action(marioState.action) ~= false) then
        return
    end

    marioState.flags = marioState.flags & ~MARIO_CAP_IN_HAND
    marioState.interactObj = nil
    marioState.usedObj = nil

    if (marioState.area.camera.mode == CAMERA_MODE_WATER_SURFACE) then
        set_camera_mode(marioState.area.camera, marioState.area.camera.defMode, 1)
    end

    local holdAction = gPlayerGrabHoldActions[gPlayerGrabHoldMode]

    if (holdAction == nil) then
        holdAction = ACT_HOLD_FREEFALL
    end

    drop_and_set_mario_action(marioState, holdAction, 0)
end

function act_player_hold_mode_increment()
    local grabHoldMode = gPlayerGrabHoldMode + 1

    if (grabHoldMode >= GRAB_HOLD_MODE_MAX) then
        grabHoldMode = GRAB_HOLD_MODE_NORMAL
    end

    gPlayerGrabHoldMode = grabHoldMode
    store_grab_hold_mode(grabHoldMode)
end

---@param marioState MarioState
function act_player_swap_hold_action(marioState)
    if (gGlobalSyncTable.allowGrabHoldModeSwap == false or gPlayerGrabHoldModeSwap == false) then
        return
    end

    if (marioState.freeze ~= 0) then
        return
    end

    local action = marioState.action

    -- check idle or swinging speed
    if (gPlayerHoldIdleActions[action] == nil or (action == ACT_HOLDING_BOWSER and math.abs(marioState.angleVel.y) > 0x200)) then
        return
    end

    act_player_hold_mode_increment()

    local grabHoldMode = gPlayerGrabHoldMode

    local holdAction = gPlayerGrabHoldActions[grabHoldMode]

    if (holdAction == nil) then
        holdAction = ACT_HOLD_FREEFALL
    end

    if (action == holdAction) then
        return
    end

    set_mario_action(marioState, holdAction, 0)
end

hook_mario_action(ACT_CUSTOM_BEING_GRABBED, {every_frame = act_custom_being_grabbed})

hook_event(HOOK_ON_SET_MARIO_ACTION, player_on_set_action)
hook_event(HOOK_ON_OBJECT_RENDER, player_on_object_render)