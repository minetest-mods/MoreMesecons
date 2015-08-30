local function dual_delayer_get_input_rules(node)
	local rules = {{x=-1, y=0, z=0}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function dual_delayer_get_output_rules(node)
	local rules = {{x=0, y=0, z=-1}, {x=0, y=0, z=1}}
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


local groups = {}
for i1=0, 1 do
for i2=0, 1 do

if not(i1 == 0 and i2 == 1) then
if i1 == 0 and i2 == 0 then
	groups = {dig_immediate = 2}
else
	groups = {dig_immediate = 2, not_in_creative_inventory = 1}
end
minetest.register_node("moremesecons_dual_delayer:dual_delayer_"..tostring(i1)..tostring(i2), {
	description = "Dual Delayer",
	drop = "moremesecons_dual_delayer:dual_delayer_00",
	inventory_image = "moremesecons_dual_delayer_00.png",
	wield_image = "moremesecons_dual_delayer_00.png",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
	type = "fixed",
	fixed = {{-6/16, -8/16, -1/16, 6/16, -7/16, 8/16 },
		{-8/16, -8/16, 1/16, -6/16, -7/16, -1/16},
		{8/16, -8/16, -1/16, 6/16, -7/16, 1/16}}
	},
	groups = groups,
	tiles = {"moremesecons_dual_delayer_"..tostring(i1)..tostring(i2)..".png", "moremesecons_dual_delayer_bottom.png", "moremesecons_dual_delayer_side_left.png", "moremesecons_dual_delayer_side_right.png", "moremesecons_dual_delayer_ends.png", "moremesecons_dual_delayer_ends.png"},
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
end
end

minetest.register_craft({
	type = "shapeless",
	output = "moremesecons_dual_delayer:dual_delayer_00 2",
	recipe = {"mesecons_delayer:delayer_off_1", "mesecons_delayer:delayer_off_1"}
})
