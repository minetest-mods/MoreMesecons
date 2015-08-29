teleporters = {}

local register = function(pos)
	local meta = minetest.env:get_meta(pos)
	local RID = meta:get_int("RID")
	if teleporters[RID] == nil then
		table.insert(teleporters, pos)
		meta:set_int("RID", #teleporters)
	end
end

local teleport_nearest = function(pos)
	local MAX_DISTANCE = 50
	
	-- Search the nearest player
	local nearest = nil
	local min_distance = math.huge
	local players = minetest.get_connected_players()
	for index, player in pairs(players) do
		local distance = vector.distance(pos, player:getpos())
		if distance < min_distance then
			min_distance = distance
			nearest = player
		end
	end
	
	-- Search other teleporter and teleport
	if not minetest.registered_nodes["moremesecons_teleporter:teleporter"] then return end
	
	local newpos = {}
	for i = 1, #teleporters do
		if minetest.get_node(teleporters[i]).name == "moremesecons_teleporter:teleporter" then
			if teleporters[i].y == pos.y and teleporters[i].x == pos.x and teleporters[i].z ~= pos.z then
				newpos = {x=teleporters[i].x, y=teleporters[i].y+1, z=teleporters[i].z}
			elseif teleporters[i].z == pos.z and teleporters[i].x == pos.x and teleporters[i].y ~= pos.y then
				newpos = {x=teleporters[i].x, y=teleporters[i].y+1, z=teleporters[i].z}
			elseif teleporters[i].z == pos.z and teleporters[i].y == pos.y and teleporters[i].x ~= pos.x then
				newpos = {x=teleporters[i].x, y=teleporters[i].y+1, z=teleporters[i].z}
			end
		end
	end
	if newpos.x then
		if vector.distance(newpos, nearest:getpos()) > MAX_DISTANCE then return end
		nearest:moveto(newpos)
		minetest.log("action", "Player "..nearest:get_player_name().." was teleport with a MoreMesecons Teleporter.")
	end	
end

minetest.register_craft({
	output = "moremesecons_teleporter:teleporter 2",
	recipe = {{"default:diamond","default:stick","default:mese"}}
})
minetest.register_node("moremesecons_teleporter:teleporter", {
	tiles = {"teleporter.png"},
	paramtype = "light",
	walkable = true,
	groups = {cracky=3},
	description="Teleporter",
	mesecons = {effector = {
		state = mesecon.state.off,
		action_on = teleport_nearest
	}},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		register(pos)
	end
})


minetest.register_abm({
	nodenames = {"moremesecons_teleporter:teleporter"},
	interval=1,
	chance=1,
	action = function(pos) 
		register(pos)
	end
})
