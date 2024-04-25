local function mesechest_get_output_rules(node)
	local rules = {{x=-1, y=0, z=0},
			{x=0, y=0, z=-1},
			{x=0, y=0, z=1}}
	for _ = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

-- default.chest.register_chest() doesn't allow to register most of the callbacks we need
-- we have to override the chest node we registered again
default.chest.register_chest("moremesecons_mesechest:mesechest", {
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

default.chest.register_chest("moremesecons_mesechest:mesechest_locked", {
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

local moremesecons_chests = {}

for _, chest in ipairs({"moremesecons_mesechest:mesechest", "moremesecons_mesechest:mesechest_locked",
						"moremesecons_mesechest:mesechest_open", "moremesecons_mesechest:mesechest_locked_open"}) do
	local old_def = minetest.registered_nodes[chest]

	local old_on_metadata_inventory_put = old_def.on_metadata_inventory_put
	local old_on_metadata_inventory_take = old_def.on_metadata_inventory_take
	local old_on_rightclick = old_def.on_rightclick

	local override = {}
	override.on_metadata_inventory_put = function(pos, ...)
		old_on_metadata_inventory_put(pos, ...)
		mesecon.receptor_on(pos, {mesechest_get_output_rules(minetest.get_node(pos))[2]})
		minetest.after(1, function(pos)
			mesecon.receptor_off(pos, {mesechest_get_output_rules(minetest.get_node(pos))[2]})
		end, pos)
	end
	override.on_metadata_inventory_take = function(pos, ...)
		old_on_metadata_inventory_take(pos, ...)
		mesecon.receptor_on(pos, {mesechest_get_output_rules(minetest.get_node(pos))[3]})
		minetest.after(1, function(pos)
			mesecon.receptor_off(pos, {mesechest_get_output_rules(minetest.get_node(pos))[3]})
		end, pos)
	end
	override.on_rightclick = function(pos, node, clicker, ...)
		if old_on_rightclick(pos, node, clicker, ...) == nil then
			mesecon.receptor_on(pos, {mesechest_get_output_rules(node)[1]})
		end
	end

	minetest.override_item(chest, override)
	moremesecons_chests[chest] = true
end

-- if the chest is getting closed, turn the signal off
-- luacheck: ignore 122
local old_lid_close = default.chest.chest_lid_close
function default.chest.chest_lid_close(pn)
	local pos = default.chest.open_chests[pn].pos
	-- old_lid_close will return true if the chest won't be closed
	if old_lid_close(pn) then
		return true
	end
	local node = minetest.get_node(pos)
	if moremesecons_chests[node.name] then
		mesecon.receptor_off(pos, {mesechest_get_output_rules(node)[1]})
	end
end

minetest.register_craft({
	output = "moremesecons_mesechest:mesechest",
	recipe = {{"group:mesecon_conductor_craftable", "default:chest", "group:mesecon_conductor_craftable"}}
})

minetest.register_craft({
	output = "moremesecons_mesechest:mesechest_locked",
	recipe = {{"group:mesecon_conductor_craftable", "default:chest_locked", "group:mesecon_conductor_craftable"}}
})

-- Legacy
minetest.register_alias("default:mesechest", "moremesecons_mesechest:mesechest")
minetest.register_alias("mesechest", "moremesecons_mesechest:mesechest")
minetest.register_alias("default:mesechest_locked", "moremesecons_mesechest:mesechest")
minetest.register_alias("mesechest_locked", "moremesecons_mesechest:mesechest_locked")
