--MOREMESECONS SWITCHTORCH
--file copy on mesecons torch by Jeija

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

local torch_get_output_rules = function(node)
	local rules = {
		{x = 1,  y = 0, z = 0},
		{x = 0,  y = 0, z = 1},
		{x = 0,  y = 0, z =-1},
		{x = 0,  y = 1, z = 0},
		{x = 0,  y =-1, z = 0}}

	return rotate_torch_rules(rules, node.param2)
end

local torch_get_input_rules = function(node)
	local rules = 	{{x = -2, y = 0, z = 0},
				 {x = -1, y = 1, z = 0}}

	return rotate_torch_rules(rules, node.param2)
end

minetest.register_craft({
	output = "moremesecons_switchtorch:switchtorch_off 4",
	recipe = {
	{"default:stick"},
	{"group:mesecon_conductor_craftable"},}
})

local torch_selectionbox =
{
	type = "wallmounted",
	wall_top = {-0.1, 0.5-0.6, -0.1, 0.1, 0.5, 0.1},
	wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.5+0.6, 0.1},
	wall_side = {-0.5, -0.1, -0.1, -0.5+0.6, 0.1, 0.1},
}

minetest.register_node("moremesecons_switchtorch:switchtorch_off", {
	drawtype = "torchlike",
	tiles = {"jeija_torches_off.png", "jeija_torches_off_ceiling.png", "jeija_torches_off_side.png"},
	inventory_image = "jeija_torches_off.png",
	paramtype = "light",
	walkable = false,
	paramtype2 = "wallmounted",
	selection_box = torch_selectionbox,
	groups = {dig_immediate = 3},
	drop = "moremesecons_switchtorch:switchtorch_on",
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = torch_get_output_rules
	}},

	on_construct = function(pos)-- For EndPower
   		local meta = minetest.get_meta(pos)
   		meta:set_int("EndPower", 1) -- 1 for true, 0 for false
	end
})

minetest.register_node("moremesecons_switchtorch:switchtorch_on", {
	descrption = "Switch Torch",
	drawtype = "torchlike",
	tiles = {"jeija_torches_on.png", "jeija_torches_on_ceiling.png", "jeija_torches_on_side.png"},
	inventory_image = "jeija_torches_on.png",
	wield_image = "jeija_torches_on.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	paramtype2 = "wallmounted",
	selection_box = torch_selectionbox,
	groups = {dig_immediate=3},
	light_source = LIGHT_MAX-5,
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = torch_get_output_rules
	}},

	on_construct = function(pos)-- For EndPower
   		local meta = minetest.get_meta(pos)
   		meta:set_int("EndPower", 1) -- 1 for true, 0 for false
	end
})

minetest.register_abm({
	nodenames = {"moremesecons_switchtorch:switchtorch_off","moremesecons_switchtorch:switchtorch_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		local is_powered = false
		for _, rule in ipairs(torch_get_input_rules(node)) do
			local src = mesecon.addPosRule(pos, rule)
			if mesecon.is_power_on(src) then
				is_powered = true
			end
		end

		local meta = minetest.get_meta(pos)
		if is_powered and meta:get_int("EndPower") == 1 then
			if node.name == "moremesecons_switchtorch:switchtorch_on" then
				minetest.swap_node(pos, {name = "moremesecons_switchtorch:switchtorch_off", param2 = node.param2})
				mesecon.receptor_off(pos, torch_get_output_rules(node))
			elseif node.name == "moremesecons_switchtorch:switchtorch_off" then
				minetest.swap_node(pos, {name = "moremesecons_switchtorch:switchtorch_on", param2 = node.param2})
				mesecon.receptor_on(pos, torch_get_output_rules(node))
			end
			meta = minetest.get_meta(pos)
			meta:set_int("EndPower", 0)
		elseif not(is_powered) and meta:get_int("EndPower") == 0 then
			meta:set_int("EndPower", 1)
		end
	end
})

-- Param2 Table (Block Attached To)
-- 5 = z-1
-- 3 = x-1
-- 4 = z+1
-- 2 = x+1
-- 0 = y+1
-- 1 = y-1
