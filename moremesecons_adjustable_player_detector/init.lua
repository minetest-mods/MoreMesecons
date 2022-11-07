-- Adjustable Player Detector
-- Detects players in a certain radius
-- The radius can be changes by right-click (by default 6)

local function make_formspec(meta)
	meta:set_string("formspec", "size[9,5]" ..
		"field[0.3,  0;9,2;scanname;Comma-separated list of the names of players to scan for (empty for any):;${scanname}]"..
		"field[0.3,1.5;4,2;digiline_channel;Digiline Channel (optional):;${digiline_channel}]"..
		"field[0.3,3;4,2;radius;Detection radius:;${radius}]"..
		"button_exit[3.5,3.5;2,3;;Save]")
end

local function object_detector_make_formspec(pos)
	make_formspec(minetest.get_meta(pos))
end

local function object_detector_on_receive_fields(pos, _, fields, player)
	if not fields.scanname
	or not fields.digiline_channel
	or minetest.is_protected(pos, player:get_player_name()) then
		return
	end

	local meta = minetest.get_meta(pos)
	meta:set_string("scanname", fields.scanname)
	meta:set_string("digiline_channel", fields.digiline_channel)
	local r = tonumber(fields.radius)
	if r then
		meta:set_int("radius", r)
	end
end

-- returns true if player was found, false if not
local object_detector_scan = function (pos)
	local meta = minetest.get_meta(pos)
	local scanname = meta:get_string("scanname")
	local scan_all = scanname == ""
	local scan_names = scanname:split(',')
	local radius = meta:get_int("radius")
	if radius <= 0 then
		radius = 6
	end
	for _,obj in pairs(minetest.get_objects_inside_radius(pos, radius)) do
		local isname = obj:get_player_name() -- "" is returned if it is not a player; "" ~= nil!
		if isname ~= "" then
			if scan_all then
				return true, isname
			end
			for _, name in ipairs(scan_names) do
				if isname == name then
					return true, isname
				end
			end
		end
	end
	return false
end

-- set player name when receiving a digiline signal on a specific channel
local object_detector_digiline = {
	effector = {
		action = function (pos, node, channel, msg)
			local meta = minetest.get_meta(pos)
			local active_channel = meta:get_string("digiline_channel")
			if channel ~= active_channel then
				return
			end
			if type(msg) == "string" then
				meta:set_string("scanname", msg)
				make_formspec(meta)
			elseif type(msg) == "table" then
				if msg.radius then
					local r = tonumber(msg.radius)
					if r then
						meta:set_int("radius", tonumber(msg.radius))
						make_formspec(meta)
					end
				end
				if msg.scanname then
					meta:set_string("scanname", msg.scanname)
					make_formspec(meta)
				end
				if msg.command and msg.command == "get" then
					local found, name = object_detector_scan(pos)
					if not found then
						name = ""
					end
					digiline:receptor_send(pos, digiline.rules.default, channel, name)
				end
			end
		end,
	},
	receptor = {}
}

minetest.register_node("moremesecons_adjustable_player_detector:player_detector_off", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "moremesecons_player_detector_off.png"},
	paramtype = "light",
	walkable = true,
	groups = {cracky=3},
	description="Adjustable Player Detector",
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.pplate
	}},
	on_construct = object_detector_make_formspec,
	on_receive_fields = object_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = object_detector_digiline
})

minetest.register_node("moremesecons_adjustable_player_detector:player_detector_on", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "moremesecons_player_detector_on.png"},
	paramtype = "light",
	walkable = true,
	groups = {cracky=3,not_in_creative_inventory=1},
	drop = 'moremesecons_adjustable_player_detector:player_detector_off',
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.pplate
	}},
	on_construct = object_detector_make_formspec,
	on_receive_fields = object_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = object_detector_digiline
})

minetest.register_craft({
	output = 'moremesecons_adjustable_player_detector:player_detector_off',
	recipe = {
		{"mesecons_detector:object_detector_off"},
		{"default:mese_crystal_fragment"}
	}
})

minetest.register_abm({
	nodenames = {"moremesecons_adjustable_player_detector:player_detector_off"},
	interval = 1.0,
	chance = 1,
	action = function(pos)
		if object_detector_scan(pos) then
			minetest.swap_node(pos, {name = "moremesecons_adjustable_player_detector:player_detector_on"})
			mesecon.receptor_on(pos, mesecon.rules.pplate)
		end
	end,
})

minetest.register_abm({
	nodenames = {"moremesecons_adjustable_player_detector:player_detector_on"},
	interval = 1.0,
	chance = 1,
	action = function(pos)
		if not object_detector_scan(pos) then
			minetest.swap_node(pos, {name = "moremesecons_adjustable_player_detector:player_detector_off"})
			mesecon.receptor_off(pos, mesecon.rules.pplate)
		end
	end,
})
