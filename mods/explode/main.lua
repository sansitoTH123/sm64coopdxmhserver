-- name: Explode
-- description: you blow up

local function restoreCharacter(m)
	set_mario_action(m,ACT_IDLE,0)
	cur_obj_enable_rendering_and_become_tangible(m.marioObj)
end

local function coinSetup(obj)
	obj.oForwardVel = random_float() * 20
	obj.oVelY = random_float() * 40 + 20
	obj.oMoveAngleYaw = random_u16()
end

local function explodeCharacter(m)
	set_mario_action(m, ACT_DISAPPEARED, 0)
	if m.playerIndex == 0 then
		spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z, nil)
		spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x, m.pos.y, m.pos.z, coinSetup)
	end
	stop_sounds_from_source(m.pos)
end

local resetTimer = -1
local function update(m)
	if m.playerIndex ~= 0 then return end
	if resetTimer ~= -1 then
		if resetTimer == 0 then
			resetTimer = -1
			if m.action == ACT_DISAPPEARED then
				restoreCharacter(m)
				network_send(true,{explode = (1 << 16 | network_global_index_from_local(0)) })
			end
		else
			resetTimer = resetTimer - 1
		end
	end
end

local function triggerExplosion()
	if gMarioStates[0].action ~= ACT_DISAPPEARED then
		explodeCharacter(gMarioStates[0])
		network_send(true,{explode = network_global_index_from_local(0) })
		resetTimer = 16*5
	end
	return true
end

local function receive(data)
	if data.explode then
		local globalIndex = data.explode & 0xFFFF
		local explodeState = data.explode >> 16 & 1
		local localIndex = network_local_index_from_global(globalIndex)
		if explodeState == 0 then
			explodeCharacter(gMarioStates[localIndex])
		elseif explodeState == 1 then
			restoreCharacter(gMarioStates[localIndex])
		end
	end
end

hook_chat_command("explode", "- blow up", triggerExplosion)
hook_event(HOOK_ON_PACKET_RECEIVE, receive)
hook_event(HOOK_MARIO_UPDATE, update)