local JAMMER_MAX_DISTANCE = 15

local wireless = {}
local wireless_rids = {}

-- localize these functions with small names because they work fairly fast
local get = vector.get_data_from_pos
local set = vector.set_data_to_pos
local remove = vector.remove_data_from_pos

-- if the wireless at pos isn't stored yet, put it into the tables
local function register_RID(pos)
	if get(wireless_rids, pos.z,pos.y,pos.x) then
		return
	end
	local RID = #wireless+1
	wireless[RID] = pos
	set(wireless_rids, pos.z,pos.y,pos.x, RID)
end

local is_jammed
local function wireless_activate(pos)
	if is_jammed(pos) then
		-- jamming doesn't disallow receiving signals, only sending them
		return
	end

	local channel_first_wireless = minetest.get_meta(pos):get_string("channel")
	if channel_first_wireless == "" then
		return
	end

	for i = 1, #wireless do
		if not vector.equals(wireless[i], pos)
		and minetest.get_meta(wireless[i]):get_string("channel") == channel_first_wireless then
			mesecon.receptor_on(wireless[i])
		end
	end
end

local function wireless_deactivate(pos)
	if is_jammed(pos) then
		return
	end
	local channel_first_wireless = minetest.get_meta(pos):get_string("channel")
	for i = 1, #wireless do
		if not vector.equals(wireless[i], pos)
		and minetest.get_meta(wireless[i]):get_string("channel") == channel_first_wireless then
			mesecon.receptor_off(wireless[i])
		end
	end
end

local function on_digiline_receive(pos, node, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel") -- Note : the digiline channel is the same as the wireless channel. TODO: Making two different channels and a more complex formspec ?
	if channel ~= setchan or is_jammed(pos) or setchan == "" then
		return
	end
	for i = 1, #wireless do
		if not vector.equals(wireless[i], pos)
		and minetest.get_meta(wireless[i]):get_string("channel") == channel then
			digiline:receptor_send(wireless[i], digiline.rules.default, channel, msg)
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
	digiline = {
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", "field[channel;channel;${channel}]")
		register_RID(pos)
	end,
	on_destruct = function(pos)
		local RID = get(wireless_rids, pos.z,pos.y,pos.x)
		if RID then
			table.remove(wireless, RID)
			vector.remove_data_from_pos(wireless_rids, pos.z,pos.y,pos.x)
		end
		mesecon.receptor_off(pos)
	end,
	on_receive_fields = function(pos, _, fields, player)
		if fields.channel
		and not minetest.is_protected(pos, player:get_player_name()) then
			minetest.get_meta(pos):set_string("channel", fields.channel)
		end
	end,
})

local jammers = {}
local function add_jammer(pos)
	if get(jammers, pos.z,pos.y,pos.x) then
		return
	end
	set(jammers, pos.z,pos.y,pos.x, true)
end

local function remove_jammer(pos)
	remove(jammers, pos.z,pos.y,pos.x)
end

-- looks big, but should work fast
function is_jammed(pos)
	local pz,py,px = vector.unpack(pos)
	for z,yxs in pairs(jammers) do
		if math.abs(pz-z) <= JAMMER_MAX_DISTANCE then
			for y,xs in pairs(yxs) do
				if math.abs(py-y) <= JAMMER_MAX_DISTANCE then
					for x in pairs(xs) do
						if math.abs(px-x) <= JAMMER_MAX_DISTANCE
						and (px-x)^2+(py-y)^2+(pz-z)^2 <= JAMMER_MAX_DISTANCE^2 then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

mesecon.register_node("moremesecons_wireless:jammer", {
	description = "Wireless Jammer",
	paramtype = "light",
	drawtype = "nodebox",
},{
	tiles = {"mesecons_wire_off.png^moremesecons_jammer_top.png", "moremesecons_jammer_bottom.png", "mesecons_wire_off.png^moremesecons_jammer_side_off.png"},
	node_box = {
		type = "fixed",
		fixed = {
			-- connection
			{-1/16, -0.5, -0.5, 1/16, -7/16, 0.5},
			{-0.5, -0.5, -1/16, 0.5, -7/16, 1/16},

			--stabilization
			{-1/16, -7/16, -1/16, 1/16, -6/16, 1/16},

			-- fields
			{-7/16, -6/16, -7/16, 7/16, -4/16, 7/16},
			{-5/16, -4/16, -5/16, 5/16, -3/16, 5/16},
			{-3/16, -3/16, -3/16, 3/16, -2/16, 3/16},
			{-1/16, -2/16, -1/16, 1/16, -1/16, 1/16},
		},
	},
	groups = {dig_immediate=2},
	mesecons = {effector = {
		rules = mesecon.rules.flat,
		action_on = function(pos)
			add_jammer(pos)
			minetest.swap_node(pos, {name="moremesecons_wireless:jammer_on"})
		end
	}}
},{
	tiles = {"mesecons_wire_on.png^moremesecons_jammer_top.png", "moremesecons_jammer_bottom.png", "mesecons_wire_on.png^moremesecons_jammer_side_on.png"},
	node_box = {
		type = "fixed",
		fixed = {
			-- connection
			{-1/16, -0.5, -0.5, 1/16, -7/16, 0.5},
			{-0.5, -0.5, -1/16, 0.5, -7/16, 1/16},

			--stabilization
			{-1/16, -7/16, -1/16, 1/16, 5/16, 1/16},

			-- fields
			{-7/16, -6/16, -7/16, 7/16, -4/16, 7/16},
			{-5/16, -3/16, -5/16, 5/16, -1/16, 5/16},
			{-3/16, 0, -3/16, 3/16, 2/16, 3/16},
			{-1/16, 3/16, -1/16, 1/16, 5/16, 1/16},
		},
	},
	groups = {dig_immediate=2, not_in_creative_inventory=1},
	mesecons = {effector = {
		rules = mesecon.rules.flat,
		action_off = function(pos)
			remove_jammer(pos)
			minetest.swap_node(pos, {name="moremesecons_wireless:jammer_off"})
		end
	}},
	on_destruct = remove_jammer,
	on_construct = add_jammer,
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

minetest.register_lbm({
	name = "moremesecons_wireless:add_jammer",
	nodenames = {"moremesecons_wireless:jammer_on"},
	run_at_every_load = true,
	action = add_jammer
})

minetest.register_lbm({
	name = "moremesecons_wireless:add_wireless",
	nodenames = {"moremesecons_wireless:wireless"},
	run_at_every_load = true,
	action = register_RID
})
