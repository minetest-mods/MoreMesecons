local rotate_torch_rules = function (rules, param2)
	if param2 == 5 then
		return mesecon.rotate_rules_right(rules)
	elseif param2 == 2 then
		return mesecon.rotate_rules_right(mesecon.rotate_rules_right(rules)) --180 degrees
	elseif param2 == 4 then
		return mesecon.rotate_rules_left(rules)
	elseif param2 == 1 then
		return mesecon.rotate_rules_down(rules)
	elseif param2 == 0 then
		return mesecon.rotate_rules_up(rules)
	else
		return rules
	end
end

local output_rules = {
	{x = 1,  y = 0, z = 0},
	{x = 0,  y = 0, z = 1},
	{x = 0,  y = 0, z =-1},
	{x = 0,  y = 1, z = 0},
	{x = 0,  y =-1, z = 0}
}
local torch_get_output_rules = function(node)
	return rotate_torch_rules(output_rules, node.param2)
end

local input_rules = {
	{x = -2, y = 0, z = 0},
	{x = -1, y = 1, z = 0}
}
local torch_get_input_rules = function(node)
	return rotate_torch_rules(input_rules, node.param2)
end

minetest.register_craft({
	output = "moremesecons_switchtorch:switchtorch_off 4",
	recipe = {
		{"default:stick"},
		{"group:mesecon_conductor_craftable"},
	}
})

local torch_selectionbox =
{
	type = "wallmounted",
	wall_top = {-0.1, 0.5-0.6, -0.1, 0.1, 0.5, 0.1},
	wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.5+0.6, 0.1},
	wall_side = {-0.5, -0.1, -0.1, -0.5+0.6, 0.1, 0.1},
}

minetest.register_node("moremesecons_switchtorch:switchtorch_off", {
	description = "Switch Torch",
	inventory_image = "moremesecons_switchtorch_on.png",
	wield_image = "moremesecons_switchtorch_on.png",
	drawtype = "torchlike",
	tiles = {"moremesecons_switchtorch_off.png", "moremesecons_switchtorch_off_ceiling.png", "moremesecons_switchtorch_off_side.png"},
	paramtype = "light",
	walkable = false,
	paramtype2 = "wallmounted",
	selection_box = torch_selectionbox,
	groups = {dig_immediate = 3},
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = torch_get_output_rules
	}},

	on_construct = function(pos)-- For EndPower
		minetest.get_meta(pos):set_int("EndPower", 1) -- 1 for true, 0 for false
	end
})

minetest.register_node("moremesecons_switchtorch:switchtorch_on", {
	drawtype = "torchlike",
	tiles = {"moremesecons_switchtorch_on.png", "moremesecons_switchtorch_on_ceiling.png", "moremesecons_switchtorch_on_side.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	paramtype2 = "wallmounted",
	selection_box = torch_selectionbox,
	groups = {dig_immediate=3, not_in_creative_inventory = 1},
	drop = "moremesecons_switchtorch:switchtorch_off",
	light_source = LIGHT_MAX-5,
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = torch_get_output_rules
	}},
})

minetest.register_abm({
	nodenames = {"moremesecons_switchtorch:switchtorch_off","moremesecons_switchtorch:switchtorch_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		local is_powered = false
		for _, rule in ipairs(torch_get_input_rules(node)) do
			local src = vector.add(pos, rule)
			if mesecon.is_power_on(src) then
				is_powered = true
				break
			end
		end

		local meta = minetest.get_meta(pos)
		if meta:get_int("EndPower") == 0 == is_powered then
			return
		end
		if not is_powered then
			meta:set_int("EndPower", 1)
			return
		end
		if node.name == "moremesecons_switchtorch:switchtorch_on" then
			minetest.swap_node(pos, {name = "moremesecons_switchtorch:switchtorch_off", param2 = node.param2})
			mesecon.receptor_off(pos, torch_get_output_rules(node))
		elseif node.name == "moremesecons_switchtorch:switchtorch_off" then
			minetest.swap_node(pos, {name = "moremesecons_switchtorch:switchtorch_on", param2 = node.param2})
			mesecon.receptor_on(pos, torch_get_output_rules(node))
		end
		meta:set_int("EndPower", 0)
	end
})

-- Param2 Table (Block Attached To)
-- 5 = z-1
-- 3 = x-1
-- 4 = z+1
-- 2 = x+1
-- 0 = y+1
-- 1 = y-1
