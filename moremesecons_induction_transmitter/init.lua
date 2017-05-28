local function induction_transmitter_get_input_rules(node)
	-- All horizontal rules, except the output
	local rules = {
		{x=-1,y=0,z=0},
		{x=1,y=0,z=0},
		{x=0,y=0,z=-1},
		{x=0,y=0,z=1}
	}
	for i, r in ipairs(rules) do
		if vector.equals(r, minetest.facedir_to_dir(node.param2)) then
			table.remove(rules, i)
		end
	end
	return rules
end

local function induction_transmitter_get_output_rules(node)
	return {vector.multiply(minetest.facedir_to_dir(node.param2), 2)}
end

local function induction_transmitter_get_virtual_output_rules(node)
	return {minetest.facedir_to_dir(node.param2)}
end

local function act(pos, node, state)
	minetest.swap_node(pos, {name = "moremesecons_induction_transmitter:induction_transmitter_"..state, param2 = node.param2})

	local dir = minetest.facedir_to_dir(node.param2)
	local target_pos = vector.add(pos, vector.multiply(dir, 2))
	local target_node = minetest.get_node(target_pos)
	if mesecon.is_effector(target_node.name) then
		-- Switch on an aside node, so it sends a signal to the target node
		local aside_rule = mesecon.effector_get_rules(target_node)[1]
		if not aside_rule then
			return
		end
		mesecon["receptor_"..state](vector.add(target_pos, aside_rule), {vector.multiply(aside_rule, -1)})
	elseif mesecon.is_conductor(target_node.name) then
		-- Switch on the conductor itself
		mesecon["receptor_"..state](target_pos, mesecon.conductor_get_rules(target_node))
	end
end

mesecon.register_node("moremesecons_induction_transmitter:induction_transmitter", {
	description = "Induction Transmitter",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0.125, 0.5, 0.5, 0.5},
			{-0.375, -0.375, -0.1875, 0.375, 0.375, 0.125},
			{-0.25, -0.25, -0.5, 0.25, 0.25, -0.1875},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0.125, 0.5, 0.5, 0.5},
			{-0.375, -0.375, -0.1875, 0.375, 0.375, 0.125},
			{-0.25, -0.25, -0.5, 0.25, 0.25, -0.1875},
		},
	},
}, {
	tiles = {"default_mese_block.png"},
	groups = {cracky = 3},
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = induction_transmitter_get_output_rules
		},
		effector = {
			rules = induction_transmitter_get_input_rules,
			action_on = function(pos, node)
				act(pos, node, "on")
			end
		}
	}
}, {
	light_source = 5,
	tiles = {"default_mese_block.png^[brighten"},
	groups = {cracky = 3, not_in_creative_inventory = 1},
	mesecons = {
		receptor = {
			state = mesecon.state.on,
			rules = induction_transmitter_get_output_rules
		},
		effector = {
			rules = induction_transmitter_get_input_rules,
			action_off = function(pos, node)
				act(pos, node, "off")
			end
		}
	}
})

minetest.register_craft({
	output = "moremesecons_induction_transmitter:induction_transmitter_off",
	recipe = {
		{"default:mese_crystal_fragment", "mesecons_torch:mesecon_torch_on", "default:mese_crystal_fragment"},
		{"", "default:mese_crystal_fragment", ""}
	}
})
