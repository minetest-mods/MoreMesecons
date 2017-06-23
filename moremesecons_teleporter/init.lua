local storage = minetest.get_mod_storage()

local teleporters = minetest.deserialize(storage:get_string("teleporters")) or {}
local teleporters_rids = minetest.deserialize(storage:get_string("teleporters_rids")) or {}
local jammers = minetest.deserialize(storage:get_string("jammers")) or {}

local function update_mod_storage()
	storage:set_string("teleporters", minetest.serialize(teleporters))
	storage:set_string("teleporters_rids", minetest.serialize(teleporters_rids))
end


local function register(pos)
	if not vector.get_data_from_pos(teleporters_rids, pos.z,pos.y,pos.x) then
		table.insert(teleporters, pos)
		vector.set_data_to_pos(teleporters_rids, pos.z,pos.y,pos.x, #teleporters)
		update_mod_storage()
	end
end

local function teleport_nearest(pos)
	local MAX_TELEPORTATION_DISTANCE = moremesecons.setting("teleporter", "max_t2t_distance", 50, 1)
	local MAX_PLAYER_DISTANCE = moremesecons.setting("teleporter", "max_p2t_distance", 25, 1)

	-- Search for the nearest player
	local nearest = nil
	local min_distance = MAX_PLAYER_DISTANCE
	local players = minetest.get_connected_players()
	for index, player in pairs(players) do
		local distance = vector.distance(pos, player:getpos())
		if distance <= min_distance then
			min_distance = distance
			nearest = player
		end
	end

	if not nearest then
		-- If there is no nearest player (maybe too far away...)
		return
	end

	-- Search for the corresponding teleporter and teleport
	if not minetest.registered_nodes["moremesecons_teleporter:teleporter"] then return end

	local newpos = {}
	local min_distance = MAX_TELEPORTATION_DISTANCE
	for i = 1, #teleporters do
		if minetest.get_node(teleporters[i]).name == "moremesecons_teleporter:teleporter" then
			local tel_pos
			if teleporters[i].y == pos.y and teleporters[i].x == pos.x and teleporters[i].z ~= pos.z then
				tel_pos = {x=teleporters[i].x, y=teleporters[i].y+1, z=teleporters[i].z}
			elseif teleporters[i].z == pos.z and teleporters[i].x == pos.x and teleporters[i].y ~= pos.y then
				tel_pos = {x=teleporters[i].x, y=teleporters[i].y+1, z=teleporters[i].z}
			elseif teleporters[i].z == pos.z and teleporters[i].y == pos.y and teleporters[i].x ~= pos.x then
				tel_pos = {x=teleporters[i].x, y=teleporters[i].y+1, z=teleporters[i].z}
			end

			if tel_pos then
				local distance = vector.distance(tel_pos, pos)
				if distance <= min_distance then
					min_distance = distance
					newpos = tel_pos
				end
			end
		end
	end
	if not newpos.x then
		newpos = {x=pos.x, y=pos.y+1, z=pos.z} -- If newpos doesn't exist, teleport on the current teleporter
	end

	nearest:moveto(newpos)
	minetest.log("action", "Player "..nearest:get_player_name().." was teleported using a MoreMesecons Teleporter.")
end

minetest.register_craft({
	output = "moremesecons_teleporter:teleporter 2",
	recipe = {{"default:diamond","default:stick","default:mese"}}
})
minetest.register_node("moremesecons_teleporter:teleporter", {
	tiles = {"moremesecons_teleporter.png"},
	paramtype = "light",
	walkable = true,
	groups = {cracky=3},
	description="Teleporter",
	mesecons = {effector = {
		state = mesecon.state.off,
		action_on = teleport_nearest
	}},
	sounds = default.node_sound_stone_defaults(),
	on_construct = register,
	on_destruct = function(pos)
		local RID = vector.get_data_from_pos(teleporters_rids, pos.z,pos.y,pos.x)
		if RID then
			table.remove(teleporters, RID)
			vector.remove_data_from_pos(teleporters_rids, pos.z,pos.y,pos.x)
			update_mod_storage()
		end
	end,
})

if moremesecons.setting("teleporter", "enable_lbm", false) then
	minetest.register_lbm({
		name = "moremesecons_teleporter:add_teleporter",
		nodenames = {"moremesecons_teleporter:teleporter"},
		run_at_every_load = true,
		action = register
	})
end
