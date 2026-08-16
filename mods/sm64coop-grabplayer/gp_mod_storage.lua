-- gp_mod_storage.lua - created by Marioiscool246 on 10/25/2024, last updated on 10/26/2024 MM/DD/YY

local MASHOUT_ENABLED_KEY = "mashout-enabled"
local GRAB_THROW_MULT_KEY = "grab-throw-mult"
local GROUND_POUND_BREAKS_GRABS_KEY = "ground-pound-breaks-grabs"
local CHECK_SAME_TEAM_KEY = "check-same-team"
local GRAB_HOLD_MODE_KEY = "grab-hold-mode"
local GRAB_HOLD_MODE_SWAP_KEY = "grab-hold-swap-enabled"
local ALLOW_GRAB_HOLD_MODE_SWAP_KEY = "allow-grab-hold-swap"

function store_mashout_enabled(value)
    mod_storage_save(MASHOUT_ENABLED_KEY, tostring(value))
end

local function load_mashout_enabled()
    local storageStr = mod_storage_load(MASHOUT_ENABLED_KEY)
    if (storageStr == nil) then
        store_mashout_enabled(gGlobalSyncTable.mashoutEnabled)
    else
        storageStr = string.lower(storageStr)
        if (storageStr == "false" or storageStr == "0") then
            gGlobalSyncTable.mashoutEnabled = false
        elseif (storageStr == "true" or storageStr == "1") then
            gGlobalSyncTable.mashoutEnabled = true
        else
            store_mashout_enabled(gGlobalSyncTable.mashoutEnabled)
        end
    end
end

function store_grab_throw_mult(value)
    if (value < 0) then
        value = 1.0
    end

    mod_storage_save(GRAB_THROW_MULT_KEY, tostring(value))
end

local function load_grab_throw_mult()
    local storageVal = tonumber(mod_storage_load(GRAB_THROW_MULT_KEY))
    if (storageVal == nil or storageVal < 0.0) then
        store_grab_throw_mult(gGlobalSyncTable.grabThrowMult)
    else
        gGlobalSyncTable.grabThrowMult = storageVal
    end
end

function store_ground_pound_breaks_grabs(value)
    mod_storage_save(GROUND_POUND_BREAKS_GRABS_KEY, tostring(value))
end

local function load_ground_pound_breaks_grabs()
    local storageStr = mod_storage_load(GROUND_POUND_BREAKS_GRABS_KEY)
    if (storageStr == nil) then
        store_ground_pound_breaks_grabs(gGlobalSyncTable.groundPoundsBreaksGrabs)
    else
        storageStr = string.lower(storageStr)
        if (storageStr == "false" or storageStr == "0") then
            gGlobalSyncTable.groundPoundsBreaksGrabs = false
        elseif (storageStr == "true" or storageStr == "1") then
            gGlobalSyncTable.groundPoundsBreaksGrabs = true
        else
            store_ground_pound_breaks_grabs(gGlobalSyncTable.groundPoundsBreaksGrabs)
        end
    end
end

function store_check_same_team(value)
    mod_storage_save(CHECK_SAME_TEAM_KEY, tostring(value))
end

local function load_check_same_team()
    local storageStr = mod_storage_load(CHECK_SAME_TEAM_KEY)
    if (storageStr == nil) then
        store_check_same_team(gGlobalSyncTable.checkSameTeam)
    else
        storageStr = string.lower(storageStr)
        if (storageStr == "false" or storageStr == "0") then
            gGlobalSyncTable.checkSameTeam = false
        elseif (storageStr == "true" or storageStr == "1") then
            gGlobalSyncTable.checkSameTeam = true
        else
            store_check_same_team(gGlobalSyncTable.checkSameTeam)
        end
    end
end

function store_grab_hold_mode(value)
    if (value >= GRAB_HOLD_MODE_MAX) then
        value = GRAB_HOLD_MODE_NORMAL
    end

    mod_storage_save(GRAB_HOLD_MODE_KEY, tostring(value))
end

local function load_grab_hold_mode()
    local storageVal = tonumber(mod_storage_load(GRAB_HOLD_MODE_KEY))
    if (storageVal == nil or storageVal >= GRAB_HOLD_MODE_MAX) then
        store_grab_hold_mode(gPlayerGrabHoldMode)
    else
        gPlayerGrabHoldMode = storageVal
    end
end

function store_grab_hold_mode_swap(value)
    mod_storage_save(GRAB_HOLD_MODE_SWAP_KEY, tostring(value))
end

local function load_grab_hold_mode_swap()
    local storageStr = mod_storage_load(GRAB_HOLD_MODE_SWAP_KEY)
    if (storageStr == nil) then
        store_grab_hold_mode_swap(gPlayerGrabHoldModeSwap)
    else
        storageStr = string.lower(storageStr)
        if (storageStr == "false" or storageStr == "0") then
            gPlayerGrabHoldModeSwap = false
        elseif (storageStr == "true" or storageStr == "1") then
            gPlayerGrabHoldModeSwap = true
        else
            store_grab_hold_mode_swap(gPlayerGrabHoldModeSwap)
        end
    end
end

function store_allow_grab_hold_mode_swap(value)
    mod_storage_save(ALLOW_GRAB_HOLD_MODE_SWAP_KEY, tostring(value))
end

local function load_allow_grab_hold_mode_swap()
    local storageStr = mod_storage_load(ALLOW_GRAB_HOLD_MODE_SWAP_KEY)
    if (storageStr == nil) then
        store_allow_grab_hold_mode_swap(gGlobalSyncTable.allowGrabHoldModeSwap)
    else
        storageStr = string.lower(storageStr)
        if (storageStr == "false" or storageStr == "0") then
            gGlobalSyncTable.allowGrabHoldModeSwap = false
        elseif (storageStr == "true" or storageStr == "1") then
            gGlobalSyncTable.allowGrabHoldModeSwap = true
        else
            store_allow_grab_hold_mode_swap(gGlobalSyncTable.allowGrabHoldModeSwap)
        end
    end
end

if (network_is_server()) then
    load_mashout_enabled()
    load_grab_throw_mult()
    load_ground_pound_breaks_grabs()
    load_check_same_team()
    load_allow_grab_hold_mode_swap()
end

load_grab_hold_mode()
load_grab_hold_mode_swap()