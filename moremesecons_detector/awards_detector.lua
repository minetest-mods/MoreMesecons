-- Awards detector
-- Detects awards of players in a certain radius

local S = minetest.get_translator(minetest.get_current_modname())

local function awards_detector_make_formspec(pos)
	local meta = minetest.get_meta(pos)
	if meta:get_string("radius") == ""  then meta:set_string("radius", "6") end
	meta:set_string("formspec", "size[9,2.5]" ..
		"field[0.3,  0;9,2;scanname;".. S("Name(s) of awards to scan for")..":;${scanname}]"..
		"field[0.3,1.5;2.5,2;radius;"..S("Radius").." (0-"..mesecon.setting("node_detector_distance_max", 10).."):;${radius}]"..
		"field[3,1.5;4,2;digiline_channel;Digiline Channel (optional):;${digiline_channel}]"..
		"button_exit[7,0.75;2,3;;Save]")
end

local function awards_detector_on_receive_fields(pos, formname, fields, sender)
	if not fields.scanname or not fields.digiline_channel then return end
	local name = sender:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos,name)
		return
	end

	local meta = minetest.get_meta(pos)
	meta:set_string("scanname", fields.scanname)
	meta:set_string("radius", fields.radius or "6")
	meta:set_string("digiline_channel", fields.digiline_channel)
	awards_detector_make_formspec(pos)
end

-- returns true if player was found, false if not
local function awards_detector_scan(pos)
	local meta = minetest.get_meta(pos)
	local scanname = meta:get_string("scanname")
	if scanname == "" then scanname = "awards_builder1" end

	local radius = meta:get_int("radius")
	local radius_max = mesecon.setting("node_detector_distance_max", 10)
	if radius < 0 then radius = 0 end
	if radius > radius_max then radius = radius_max end

	local objs = minetest.get_objects_inside_radius(pos, radius)

	-- abort if no scan results were found
	if next(objs) == nil then return false end


	local scan_for = {}
	for _, str in pairs(string.split(scanname:gsub(" ", ""), ",")) do
		scan_for[str] = 0
	end
--[[
	for _, obj in pairs(objs) do
		if obj:is_player() then
			local awards_list = awards.get_award_states(obj:get_player_name())
			if not (#awards_list == 0) then
				for _, award in pairs(awards_list) do
					if award.unlocked and scan_for[award.name] ~= nil then
						scan_for[award.name] = scan_for[award.name] + 1
					end
				end
			end
		end
	end

	for award, num_players in pairs(scan_for) do
		if num_players == 0 then return false end
	end

	return true
--]]

	for _, obj in pairs(objs) do
		if obj:is_player() then
			local accepted = true
			for award, _ in pairs(scan_for) do
				if awards.player(obj:get_player_name()).unlocked[award] == nil then
					accepted = false
				end
			end
			if accepted then return true end
		end
	end

	return false
end

-- set player name when receiving a digiline signal on a specific channel
local awards_detector_digiline = {
	effector = {
		action = function(pos, node, channel, msg)
			local meta = minetest.get_meta(pos)
			if channel == meta:get_string("digiline_channel") then
				meta:set_string("scanname", msg)
				awards_detector_make_formspec(pos)
			end
		end,
	}
}

minetest.register_node("moremesecons_detector:awards_detector_off", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png^(awards_ui_icon.png^[resize:16x16)", "default_steel_block.png^(awards_ui_icon.png^[resize:16x16)", "default_steel_block.png^(awards_ui_icon.png^[resize:16x16)", "default_steel_block.png^(awards_ui_icon.png^[resize:16x16)"},
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3},
	description="Awards detector",
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.pplate
	}},
	on_construct = awards_detector_make_formspec,
	on_receive_fields = awards_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = awards_detector_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("moremesecons_detector:awards_detector_on", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png^(awards_ui_icon.png^[resize:16x16^[invert:rg)", "default_steel_block.png^(awards_ui_icon.png^[resize:16x16^[invert:rg)", "default_steel_block.png^(awards_ui_icon.png^[resize:16x16^[invert:rg)", "default_steel_block.png^(awards_ui_icon.png^[resize:16x16^[invert:rg)"},
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3,not_in_creative_inventory=1},
	drop = 'moremesecons_detector:awards_detector_off',
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.pplate
	}},
	on_construct = awards_detector_make_formspec,
	on_receive_fields = awards_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = awards_detector_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = 'moremesecons_detector:awards_detector_off',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "mesecons_luacontroller:luacontroller0000", "group:mesecon_conductor_craftable"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = 'moremesecons_detector:awards_detector_off',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "mesecons_microcontroller:microcontroller0000", "group:mesecon_conductor_craftable"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_abm({
	nodenames = {"moremesecons_detector:awards_detector_off"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if not awards_detector_scan(pos) then return end

		node.name = "moremesecons_detector:awards_detector_on"
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos, mesecon.rules.pplate)
	end,
})

minetest.register_abm({
	nodenames = {"moremesecons_detector:awards_detector_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if awards_detector_scan(pos) then return end

		node.name = "moremesecons_detector:awards_detector_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, mesecon.rules.pplate)
	end,
})
