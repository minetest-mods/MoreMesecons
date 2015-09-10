local JAMMER_MAX_DISTANCE = 15

local wireless = {}
local wireless_rids = {}


local register = function(pos)
	local RID = vector.get_data_from_pos(wireless_rids, pos.z,pos.y,pos.x)
	if not RID then
		table.insert(wireless, pos)
		vector.set_data_to_pos(wireless_rids, pos.z,pos.y,pos.x, #wireless)
	end
end

local wireless_activate = function(pos)
	if not minetest.registered_nodes["moremesecons_wireless:wireless"] then return end
	local channel_first_wireless = nil
	
	for i = 1, #wireless do
		meta = minetest.get_meta(pos)
		channel_first_wireless = meta:get_string("channel")
		meta = minetest.get_meta(wireless[i])
		if wireless[i] ~= pos and meta:get_string("channel") == channel_first_wireless and not minetest.find_node_near(pos, JAMMER_MAX_DISTANCE, {"moremesecons_wireless:jammer_on"}) then
			mesecon.receptor_on(wireless[i])
		end
	end	
end

local wireless_deactivate = function(pos)
	if not minetest.registered_nodes["moremesecons_wireless:wireless"] then return end
	local meta = minetest.get_meta(pos)
	local channel_first_wireless = nil
	
	for i = 1, #wireless do
		meta = minetest.get_meta(pos)
		channel_first_wireless = meta:get_string("channel")
		meta = minetest.get_meta(wireless[i])
		if wireless[i] ~= pos and meta:get_string("channel") == channel_first_wireless and not minetest.find_node_near(pos, JAMMER_MAX_DISTANCE, {"moremesecons_wireless:jammer_on"}) then
			mesecon.receptor_off(wireless[i])
		end
	end	
end

minetest.register_node("moremesecons_wireless:wireless", {
	tiles = {"moremesecons_wireless.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	description = "Wireless",
	walkable = true,
	groups = {cracky=3},
	mesecons = {effector = {
		action_on = wireless_activate,
		action_off = wireless_deactivate
	}},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
   		meta:set_string("formspec", "field[channel;channel;${channel}]")
   		register(pos)
	end,
	on_destruct = function(pos)
		local RID = vector.get_data_from_pos(wireless_rids, pos.z,pos.y,pos.x)
		if RID then
			table.remove(wireless, RID)
			vector.remove_data_from_pos(wireless_rids, pos.z,pos.y,pos.x)
		end
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		meta:set_string("channel", fields.channel)
	end,
})

mesecon.register_node("moremesecons_wireless:jammer", {
	description="Wireless Jammer",
	paramtype = "light",
},{
	tiles = {"moremesecons_jammer_off.png"},
	groups = {dig_immediate=2},
	mesecons = {effector = {
		action_on = function(pos)
			table.foreach(pos, print)
			minetest.swap_node(pos, {name="moremesecons_wireless:jammer_on"})
		end }}
},{
	tiles = {"moremesecons_jammer_on.png"},
	groups = {dig_immediate=2, not_in_creative_inventory=1},
	mesecons = {effector = {
		action_off = function(pos)
			minetest.swap_node(pos, {name="moremesecons_wireless:jammer_off"})
		end }}
})

minetest.register_craft({
	output = "moremesecons_wireless:jammer_off",
	recipe = {
		{"moremesecons_wireless:wireless", "mesecons_torch:mesecon_torch_on", "moremesecons_wireless:wireless"}
	}
})

minetest.register_craft({
	output = "moremesecons_wireless:wireless 2",
	recipe = {
		{"group:mesecon_conductor_craftable", "", "group:mesecon_conductor_craftable"},
		{"", "mesecons_torch:mesecon_torch_on", ""},
		{"group:mesecon_conductor_craftable", "", "group:mesecon_conductor_craftable"},
	}
})

minetest.register_abm({
	nodenames = {"moremesecons_wireless:wireless"},
	interval=1,
	chance=1,
	action = register
})
