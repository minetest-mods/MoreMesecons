-- Inventory scanner
-- Detects inventory items of players in a certain radius

local S = minetest.get_translator(minetest.get_current_modname())

local function inventory_scanner_make_formspec(pos)
	local meta = minetest.get_meta(pos)
	if meta:get_string("radius") == ""  then meta:set_string("radius", "6") end
	meta:set_string("formspec", "size[9,2.5]" ..
		"field[0.3,  0;9,2;scanname;"..S("Name of item to scan for (empty for any)")..":;${scanname}]"..
		"field[0.3,1.5;2.5,2;radius;Radius (0-"..mesecon.setting("node_detector_distance_max", 10).."):;${radius}]"..
		"field[3,1.5;4,2;digiline_channel;Digiline Channel (optional):;${digiline_channel}]"..
		"button_exit[7,0.75;2,3;;Save]")
end

local function inventory_scanner_on_receive_fields(pos, formname, fields, sender)
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
	inventory_scanner_make_formspec(pos)
end

-- returns true if player was found who has any of the items in their posession, false if not
local function inventory_scanner_scan(pos)
	local meta = minetest.get_meta(pos)
	local scanname = meta:get_string("scanname")

	local radius = meta:get_int("radius")
	local radius_max = mesecon.setting("node_detector_distance_max", 10)
	if radius < 0 then radius = 0 end
	if radius > radius_max then radius = radius_max end

	local objs = minetest.get_objects_inside_radius(pos, radius)

	-- abort if no scan results were found
	if next(objs) == nil then return false end

	local scan_for = {}
	for _, str in pairs(string.split(scanname:gsub(" ", ""), ",")) do
		scan_for[str] = true
	end

	local has_items = false

	for _, obj in pairs(objs) do
		if obj:is_player() then
			local inv = obj:get_inventory()
			if not inv:is_empty("main") then
				has_items = true
			end
			for itemname, _ in pairs(scan_for) do
				if inv:contains_item("main", itemname) then
					return true
				end
			end
		end
	end

	-- scanname empty: search for any items
	if scanname == "" and has_items then return true end

	return false
end

-- set what to search for, when receiving a digiline signal on a specific channel
local inventory_scanner_digiline = {
	effector = {
		action = function(pos, node, channel, msg)
			local meta = minetest.get_meta(pos)
			if channel == meta:get_string("digiline_channel") then
				meta:set_string("scanname", msg)
				inventory_scanner_make_formspec(pos)
			end
		end,
	}
}

minetest.register_node("moremesecons_detector:inventory_scanner_off", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png^(creative_search_icon.png^[resize:16x16^[colorize:red:210)", "default_steel_block.png^(creative_search_icon.png^[resize:16x16^[colorize:red:210)", "default_steel_block.png^(creative_search_icon.png^[resize:16x16^[colorize:red:210)", "default_steel_block.png^(creative_search_icon.png^[resize:16x16^[colorize:red:210)"},
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3},
	description="Inventory Scanner",
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.pplate
	}},
	on_construct = inventory_scanner_make_formspec,
	on_receive_fields = inventory_scanner_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = inventory_scanner_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("moremesecons_detector:inventory_scanner_on", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png^(creative_search_icon.png^[resize:16x16^[colorize:green:210)", "default_steel_block.png^(creative_search_icon.png^[resize:16x16^[colorize:green:210)", "default_steel_block.png^(creative_search_icon.png^[resize:16x16^[colorize:green:210)", "default_steel_block.png^(creative_search_icon.png^[resize:16x16^[colorize:green:210)"},
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3,not_in_creative_inventory=1},
	drop = 'moremesecons_detector:inventory_scanner_off',
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.pplate
	}},
	on_construct = inventory_scanner_make_formspec,
	on_receive_fields = inventory_scanner_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = inventory_scanner_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = 'moremesecons_detector:inventory_scanner_off',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"group:mesecon_conductor_craftable", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = 'moremesecons_detector:inventory_scanner_off',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"group:mesecon_conductor_craftable", "mesecons_microcontroller:microcontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_abm({
	nodenames = {"moremesecons_detector:inventory_scanner_off"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if not inventory_scanner_scan(pos) then return end

		node.name = "moremesecons_detector:inventory_scanner_on"
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos, mesecon.rules.pplate)
	end,
})

minetest.register_abm({
	nodenames = {"moremesecons_detector:inventory_scanner_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if inventory_scanner_scan(pos) then return end

		node.name = "moremesecons_detector:inventory_scanner_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, mesecon.rules.pplate)
	end,
})
