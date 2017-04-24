local timegate_get_output_rules = function(node)
	local rules = {{x = 0, y = 0, z = 1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local timegate_get_input_rules = function(node)
	local rules = {{x = 0, y = 0, z = -1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

-- Functions that are called after the delay time

local function timegate_activate(pos, node)
	-- using a meta string allows writing the time in hexadecimals
	local time = tonumber(minetest.get_meta(pos):get_string("time"))
	if not time then
		return
	end
	node.name = "moremesecons_timegate:timegate_on"
	minetest.swap_node(pos, node)
	mesecon.receptor_on(pos)
	minetest.after(time, function(pos, node)
		mesecon.receptor_off(pos)
		node.name = "moremesecons_timegate:timegate_off"
		minetest.swap_node(pos, node)
	end, pos, node)
end

boxes = {{ -6/16, -8/16, -6/16, 6/16, -7/16, 6/16 },		-- the main slab

	 { -2/16, -7/16, -4/16, 2/16, -26/64, -3/16 },		-- the jeweled "on" indicator
	 { -3/16, -7/16, -3/16, 3/16, -26/64, -2/16 },
	 { -4/16, -7/16, -2/16, 4/16, -26/64, 2/16 },
	 { -3/16, -7/16,  2/16, 3/16, -26/64, 3/16 },
	 { -2/16, -7/16,  3/16, 2/16, -26/64, 4/16 },

	 { -6/16, -7/16, -6/16, -4/16, -27/64, -4/16 },		-- the timer indicator
	 { -8/16, -8/16, -1/16, -6/16, -7/16, 1/16 },		-- the two wire stubs
	 { 6/16, -8/16, -1/16, 8/16, -7/16, 1/16 }}

mesecon.register_node("moremesecons_timegate:timegate", {
	description = "Time Gate",
	drawtype = "nodebox",
	inventory_image = "moremesecons_timegate_off.png",
	wield_image = "moremesecons_timegate_off.png",
	walkable = true,
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
	},
	node_box = {
		type = "fixed",
		fixed = boxes
	},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	is_ground_content = true,
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", "field[time;time;${time}]")
	end,
	on_receive_fields = function(pos, _, fields, player)
		if fields.time
		and not minetest.is_protected(pos, player:get_player_name()) then
			minetest.get_meta(pos):set_string("time", fields.time)
		end
	end
},{
		tiles = {
			"moremesecons_timegate_off.png",
			"moremesecons_timegate_bottom.png",
			"moremesecons_timegate_ends_off.png",
			"moremesecons_timegate_ends_off.png",
			"moremesecons_timegate_sides_off.png",
			"moremesecons_timegate_sides_off.png"
		},
		groups = {bendy=2,snappy=1,dig_immediate=2},
		mesecons = {
			receptor =
			{
				state = mesecon.state.off,
				rules = timegate_get_output_rules
			},
			effector =
			{
				rules = timegate_get_input_rules,
				action_on = timegate_activate
			}
		},
},{
		tiles = {
			"moremesecons_timegate_on.png",
			"moremesecons_timegate_bottom.png",
			"moremesecons_timegate_ends_on.png",
			"moremesecons_timegate_ends_on.png",
			"moremesecons_timegate_sides_on.png",
			"moremesecons_timegate_sides_on.png"
		},
		groups = {bendy=2,snappy=1,dig_immediate=2, not_in_creative_inventory=1},
		mesecons = {
			receptor = {
				state = mesecon.state.on,
				rules = timegate_get_output_rules
			},
			effector = {
				rules = timegate_get_input_rules,
			}
		},
})

minetest.register_craft({
	output = "moremesecons_timegate:timegate_off 2",
	recipe = {
		{"group:mesecon_conductor_craftable", "mesecons_delayer:delayer_off_1", "group:mesecon_conductor_craftable"},
		{"default:wood","default:wood", "default:wood"},
	}
})

minetest.register_alias("moremesecons_temporarygate:temporarygate_off", "moremesecons_timegate:timegate_off")
minetest.register_alias("moremesecons_temporarygate:temporarygate_on", "moremesecons_timegate:timegate_on")
