local function dual_delayer_get_input_rules(node)
	local rules = {{x=1, y=0, z=0}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function dual_delayer_get_output_rules(node)
	local rules = {{x=0, y=0, z=1}, {x=0, y=0, z=-1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local dual_delayer_activate = function(pos, node)
	mesecon.receptor_on(pos, {dual_delayer_get_output_rules(node)[1]}) -- Turn on the port 1
	minetest.swap_node(pos, {name = "moremesecons_dual_delayer:dual_delayer_10", param2 = node.param2})
	minetest.after(0.4, function(pos, node)
		mesecon.receptor_on(pos, {dual_delayer_get_output_rules(node)[2]}) -- Turn on the port 2
		minetest.swap_node(pos, {name = "moremesecons_dual_delayer:dual_delayer_11", param2 = node.param2})
	end, pos, node)
end

local dual_delayer_deactivate = function(pos, node, link)
	mesecon.receptor_off(pos, {dual_delayer_get_output_rules(node)[2]}) -- Turn off the port 2
	minetest.swap_node(pos, {name = "moremesecons_dual_delayer:dual_delayer_10", param2 = node.param2})
	minetest.after(0.4, function(pos, node)
		mesecon.receptor_off(pos, {dual_delayer_get_output_rules(node)[1]}) -- Turn off the port 1
		minetest.swap_node(pos, {name = "moremesecons_dual_delayer:dual_delayer_00", param2 = node.param2})
	end, pos, node)
end


for n,i in pairs({{0,0},{1,0},{1,1}}) do
	local i1,i2 = unpack(i)

	local groups = {dig_immediate = 2}
	if n ~= 1 then
		groups.not_in_creative_inventory = 1
	end

	local top_texture = "^moremesecons_dual_delayer_overlay.png^[makealpha:255,126,126"
	if i1 == i2 then
		if i1 == 0 then
			top_texture = "mesecons_wire_off.png"..top_texture
		else
			top_texture = "mesecons_wire_on.png"..top_texture
		end
	else
		local pre = "mesecons_wire_off.png^[lowpart:50:mesecons_wire_on.png^[transformR"
		if i1 == 0 then
			pre = pre.. 90
		else
			pre = pre.. 270
		end
		top_texture = pre..top_texture
	end

	minetest.register_node("moremesecons_dual_delayer:dual_delayer_"..i1 ..i2, {
		description = "Dual Delayer",
		drop = "moremesecons_dual_delayer:dual_delayer_00",
		inventory_image = top_texture,
		wield_image = top_texture,
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {{-6/16, -8/16, -8/16, 6/16, -7/16, 1/16 },
				{-8/16, -8/16, 1/16, -6/16, -7/16, -1/16},
				{8/16, -8/16, -1/16, 6/16, -7/16, 1/16}}
		},
		groups = groups,
		tiles = {top_texture, "moremesecons_dual_delayer_bottom.png", "moremesecons_dual_delayer_side_left.png", "moremesecons_dual_delayer_side_right.png", "moremesecons_dual_delayer_ends.png", "moremesecons_dual_delayer_ends.png"},
		mesecons = {
			receptor = {
				state = mesecon.state.off,
				rules = dual_delayer_get_output_rules
			},
			effector = {
				rules = dual_delayer_get_input_rules,
				action_on = dual_delayer_activate,
				action_off = dual_delayer_deactivate
			}
		}
	})
end

minetest.register_craft({
	type = "shapeless",
	output = "moremesecons_dual_delayer:dual_delayer_00 2",
	recipe = {"mesecons_delayer:delayer_off_1", "mesecons_delayer:delayer_off_1"}
})
