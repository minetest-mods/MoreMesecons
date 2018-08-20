local kill_nearest_player = function(pos)
	local MAX_DISTANCE = moremesecons.setting("playerkiller", "max_distance", 8, 1)

	-- Search the nearest player
	local nearest
	local min_distance = MAX_DISTANCE
	for index, player in pairs(minetest.get_connected_players()) do
		local distance = vector.distance(pos, player:getpos())
		if distance < min_distance then
			min_distance = distance
			nearest = player
		end
	end

	if not nearest then
		-- no nearby player
		return
	end

	local owner = minetest.get_meta(pos):get_string("owner")
	if not owner then
		-- maybe some mod placed it
		return
	end

	if owner == nearest:get_player_name() then
		-- don't kill the owner !
		return
	end

	-- And kill him
	nearest:set_hp(0)
	minetest.log("action", "Player "..owner.." kills player "..nearest:get_player_name().." using a MoreMesecons Player Killer.")
end

minetest.register_craft({
	output = "moremesecons_playerkiller:playerkiller",
	recipe = {	{"","default:mese",""},
			{"default:apple","mesecons_detector:object_detector_off","default:apple"},
			{"","default:apple",""}}
})

minetest.register_node("moremesecons_playerkiller:playerkiller", {
	description = "Player Killer",
	tiles = {"moremesecons_playerkiller_top.png", "moremesecons_playerkiller_top.png", "moremesecons_playerkiller_side.png"},
	paramtype = "light",
	walkable = true,
	groups = {cracky=3},
	mesecons = {effector = {
		state = mesecon.state.off,
		action_on = kill_nearest_player
	}},
	after_place_node = function(pos, placer)
		if not placer then
			return
		end
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext", "PlayerKiller owned by " .. meta:get_string("owner"))
	end,
	sounds = default.node_sound_stone_defaults(),
})
