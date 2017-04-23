local nodebox = {
	type = "fixed",
	fixed = {{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }},
}

local function signalchanger_get_output_rules(node)
	local rules = {{x=-1, y=0, z=0},
			{x=1, y=0, z=0}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function signalchanger_get_input_rules(node)
	local rules = {{x=0, y=0, z=-1, name="input_on"}, {x=0, y=0, z=1, name="input_off"}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local update = function(pos, node, link, newstate)
	local meta = minetest.get_meta(pos)
	meta:set_int(link.name, newstate == "on" and 1 or 0)
	local input_on = meta:get_int("input_on") == 1
	local input_off = meta:get_int("input_off") == 1
	if input_on then
		mesecon.receptor_on(pos, {signalchanger_get_output_rules(node)[1]})
		mesecon.receptor_off(pos, {signalchanger_get_output_rules(node)[2]})
		minetest.swap_node(pos, {name = "moremesecons_signalchanger:signalchanger_on", param2 = node.param2})
	elseif input_off then
		mesecon.receptor_off(pos, {signalchanger_get_output_rules(node)[1]})
		mesecon.receptor_on(pos, {signalchanger_get_output_rules(node)[2]})
		minetest.swap_node(pos, {name = "moremesecons_signalchanger:signalchanger_off", param2 = node.param2})
	end
end

mesecon.register_node("moremesecons_signalchanger:signalchanger", {
	description = "Signal Changer",
	inventory_image = "moremesecons_signalchanger_off.png",
	groups = {dig_immediate = 2},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	selection_box = nodebox,
	node_box = nodebox,
},{
	groups = {dig_immediate = 2},
	mesecons = {
		receptor = {
			rules = signalchanger_get_output_rules
		},
		effector = {
			rules = signalchanger_get_input_rules,
			action_change = update
		},
	},
	tiles = {"moremesecons_signalchanger_off.png"},
	on_construct = function(pos)
		local node = minetest.get_node(pos)
		mesecon.receptor_on(pos, {signalchanger_get_output_rules(node)[2]})
	end
},{
	groups = {dig_immediate = 2, not_in_creative_inventory = 1},
	mesecons = {
		receptor = {
			rules = signalchanger_get_output_rules,
		},
		effector = {
			rules = signalchanger_get_input_rules,
			action_change = update,
		},
	},
	tiles = {"moremesecons_signalchanger_on.png"},
})

minetest.register_craft({
	output = "moremesecons_signalchanger:signalchanger_off",
	recipe = {{"group:mesecon_conductor_craftable","moremesecons_switchtorch:switchtorch_off","group:mesecon_conductor_craftable"}}
})
