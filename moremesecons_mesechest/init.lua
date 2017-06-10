local function mesechest_get_output_rules(node)
	local rules = {{x=-1, y=0, z=0},
			{x=0, y=0, z=-1},
			{x=0, y=0, z=1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end


local open_chests = {}

-- Override minetest.register_node so it adds a prefix ":"
local old_minetest_register_node = minetest.register_node
minetest.register_node = function(name, def)
	local old_on_metadata_inventory_put = def.on_metadata_inventory_put
	local old_on_metadata_inventory_take = def.on_metadata_inventory_take
	local old_on_rightclick = def.on_rightclick

	def.on_metadata_inventory_put = function(pos, ...)
		old_on_metadata_inventory_put(pos, ...)
		mesecon.receptor_on(pos, {mesechest_get_output_rules(minetest.get_node(pos))[2]})
		minetest.after(1, function(pos)
			mesecon.receptor_off(pos, {mesechest_get_output_rules(minetest.get_node(pos))[2]})
		end, pos)
	end
	def.on_metadata_inventory_take = function(pos, ...)
		old_on_metadata_inventory_take(pos, ...)
		mesecon.receptor_on(pos, {mesechest_get_output_rules(minetest.get_node(pos))[3]})
		minetest.after(1, function(pos)
			mesecon.receptor_off(pos, {mesechest_get_output_rules(minetest.get_node(pos))[3]})
		end, pos)
	end
	def.on_rightclick = function(pos, node, clicker, ...)
		if old_on_rightclick(pos, node, clicker, ...) == nil then
			mesecon.receptor_on(pos, {mesechest_get_output_rules(node)[1]})
			open_chests[clicker:get_player_name()] = pos
		end
	end

	old_minetest_register_node(":"..name, def)
end
local old_minetest_register_lbm = minetest.register_lbm
minetest.register_lbm = function() end

-- Get the on_player_receive_fields function. That's a huge hack
for i, f in ipairs(minetest.registered_on_player_receive_fields) do
	local serialized = minetest.serialize(f)
	if string.find(serialized, "default:chest") then
		minetest.registered_on_player_receive_fields[i] = function(player, formname, fields)
			if f(player, formname, fields) == true then
				local pn = player:get_player_name()
				if open_chests[pn] then
					mesecon.receptor_off(open_chests[pn], {mesechest_get_output_rules(minetest.get_node(open_chests[pn]))[1]})
					open_chests[pn] = nil
				end
			end
		end
		break
	end
end

default.register_chest("mesechest", {
	description = "Mese Chest",
	tiles = {
		"default_chest_top.png^[colorize:#d8e002:70",
		"default_chest_top.png^[colorize:#d8e002:70",
		"default_chest_side.png^[colorize:#d8e002:70",
		"default_chest_side.png^[colorize:#d8e002:70",
		"default_chest_front.png^[colorize:#d8e002:70",
		"default_chest_inside.png^[colorize:#d8e002:70"
	},
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	mesecons = {
		receptor = {
			rules = mesechest_get_output_rules
		}
	}
})

default.register_chest("mesechest_locked", {
	description = "Locked Mese Chest",
	tiles = {
		"default_chest_top.png^[colorize:#d8e002:70",
		"default_chest_top.png^[colorize:#d8e002:70",
		"default_chest_side.png^[colorize:#d8e002:70",
		"default_chest_side.png^[colorize:#d8e002:70",
		"default_chest_lock.png^[colorize:#d8e002:70",
		"default_chest_inside.png^[colorize:#d8e002:70"
	},
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	protected = true,
	mesecons = {
		receptor = {
			rules = mesechest_get_output_rules
		}
	}
})

minetest.register_node = old_minetest_register_node
minetest.register_lbm = old_minetest_register_lbm

minetest.register_craft({
	output = "default:mesechest",
	recipe = {{"group:mesecon_conductor_craftable", "default:chest", "group:mesecon_conductor_craftable"}}
})

minetest.register_craft({
	output = "default:mesechest_locked",
	recipe = {{"group:mesecon_conductor_craftable", "default:chest_locked", "group:mesecon_conductor_craftable"}}
})
