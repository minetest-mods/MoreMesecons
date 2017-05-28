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


--[[
default.register_chest prefixes chest names with "default:"
and registers an LBM. Hack: override functions used by
default.register_chest
]]
local old_register_lbm = minetest.register_lbm
minetest.register_lbm = function() end

local old_register_node = minetest.register_node
minetest.register_node = function(name, def)
	name = string.gsub(name, "default:", "")

	def.drop = def.drop and string.gsub(def.drop, "default:", "")

	local old_on_blast = def.on_blast
	def.on_blast = function(pos)
		local drops = old_on_blast(pos)
		drops[#drops] = name
		return drops
	end

	local old_on_construct = def.on_construct
	def.on_construct = function(pos)
		old_on_construct(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", string.gsub(meta:get_string("infotext"), "Chest", "Mese Chest"))
	end
	if def.after_place_node then
		local old_after_place_node = def.after_place_node
		def.after_place_node = function(pos, placer)
			old_after_place_node(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", string.gsub(meta:get_string("infotext"), "Chest", "Mese Chest"))
		end
	end

	-- Mesecons functions
	local old_on_metadata_inventory_move = def.on_metadata_inventory_put
	def.on_metadata_inventory_put = function(pos, ...)
		old_on_metadata_inventory_move(pos, ...)
		mesecon.receptor_on(pos, {mesechest_get_output_rules(minetest.get_node(pos))[2]})
		minetest.after(1, function(pos)
			mesecon.receptor_off(pos, {mesechest_get_output_rules(minetest.get_node(pos))[2]})
		end, pos)
	end

	local old_on_metadata_inventory_take = def.on_metadata_inventory_take
	def.on_metadata_inventory_take = function(pos, ...)
		old_on_metadata_inventory_take(pos, ...)
		mesecon.receptor_on(pos, {mesechest_get_output_rules(minetest.get_node(pos))[3]})
		minetest.after(1, function(pos)
			mesecon.receptor_off(pos, {mesechest_get_output_rules(minetest.get_node(pos))[3]})
		end, pos)
	end

	local old_on_rightclick = def.on_rightclick
	def.on_rightclick = function(pos, node, clicker, ...)
		if old_on_rightclick(pos, node, clicker, ...) == nil then
			mesecon.receptor_on(pos, {mesechest_get_output_rules(node)[1]})
			open_chests[clicker:get_player_name()] = pos
		end
	end

	old_register_node(name, def)
end

-- Get the on_player_receive_fields function. That's a huge hack
for i, f in ipairs(minetest.registered_on_player_receive_fields) do
	local serialized = minetest.serialize(f)
	if string.find(serialized, "default:chest") then
		minetest.registered_on_player_receive_fields[i] = function(player, formname, fields)
			if f(player, formname, fields) == true then
				local pn = player:get_player_name()
				mesecon.receptor_off(open_chests[pn], {mesechest_get_output_rules(minetest.get_node(open_chests[pn]))[1]})
				open_chests[pn] = nil
			end
		end
		break
	end
end

-- This function is permanently overwritten
local old_swap_node = minetest.swap_node
minetest.swap_node = function(pos, node)
	if node.name == "default:moremesecons_mesechest:mesechest" then
		node.name = "moremesecons_mesechest:mesechest"
	elseif node.name == "default:moremesecons_mesechest:mesechest_open" then
		node.name = "moremesecons_mesechest:mesechest_open"
	elseif node.name == "default:moremesecons_mesechest:mesechest_locked" then
		node.name = "moremesecons_mesechest:mesechest_locked"
	elseif node.name == "default:moremesecons_mesechest:mesechest_locked_open" then
		node.name = "moremesecons_mesechest:mesechest_locked_open"
	end
	old_swap_node(pos, node)
end

default.register_chest("moremesecons_mesechest:mesechest", {
	description = "Mese Chest",
	tiles = { "default_chest_wood.png" },
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

default.register_chest("moremesecons_mesechest:mesechest_locked", {
	description = "Locked Mese Chest",
	tiles = { "default_chest_wood_locked.png" },
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

minetest.register_lbm = old_register_lbm
minetest.register_node = old_register_node
