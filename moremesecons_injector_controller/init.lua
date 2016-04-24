local injector_controller_get_output_rules = function(node)
	local rules = {{x = 0, y = 0, z = 1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local injector_controller_get_input_rules = function(node)
	local rules = {{x = 0, y = 0, z = -1},
			{x = 1, y = 0, z = 0},
			{x = -1, y = 0, z = 0}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local start_timer = function(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(1)
end
local stop_timer = function(pos, node)
	local timer = minetest.get_node_timer(pos)
	timer:stop()
	mesecon.receptor_off(pos, injector_controller_get_output_rules(node))
	minetest.swap_node(pos, {name="moremesecons_injector_controller:injector_controller_off", param2=node.param2})
end

local on_timer = function(pos)
	local node = minetest.get_node(pos)
	if(mesecon.flipstate(pos, node) == "on") then
		mesecon.receptor_on(pos, injector_controller_get_output_rules(node))
	else
		mesecon.receptor_off(pos, injector_controller_get_output_rules(node))
	end
	start_timer(pos)
end

mesecon.register_node("moremesecons_injector_controller:injector_controller", {
	description="Injector Controller",
	drawtype = "nodebox",
	inventory_image = "moremesecons_injector_controller_off.png",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }},
	},
	on_timer = on_timer,
},{
	tiles = {"moremesecons_injector_controller_off.png", "moremesecons_injector_controller_side.png", "moremesecons_injector_controller_side.png"},
	groups = {dig_immediate=2},
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = injector_controller_get_output_rules
		},
		effector = {
			rules = injector_controller_get_input_rules,
			action_on = start_timer,
			action_off = stop_timer,
		}
	}
},{
	tiles = {"moremesecons_injector_controller_on.png", "moremesecons_injector_controller_side.png", "moremesecons_injector_controller_side.png"},
	groups = {dig_immediate=2, not_in_creative_inventory=1},
	mesecons = {
		receptor = {
			state = mesecon.state.on,
			rules = injector_controller_get_output_rules
		},
		effector = {
			rules = injector_controller_get_input_rules,
			action_off = stop_timer,
			action_on = start_timer,
		}
	}
})

minetest.register_craft({
	output = "moremesecons_injector_controller:injector_controller_off",
	recipe = {{"mesecons_blinkyplant:blinky_plant_off","mesecons_gates:and_off"}}
})
