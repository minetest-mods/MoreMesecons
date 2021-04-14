local storage = minetest.get_mod_storage()

-- Names wireless_meta, and jammers were used in old versions of this mod.
-- There is legacy code at the end of this file to migrate the mod storage.
local wireless = minetest.deserialize(storage:get_string("networks")) or {}
local wireless_meta = moremesecons.get_storage_data(storage, "wireless_meta_2")
local jammers = moremesecons.get_storage_data(storage, "jammers_2")

local function update_mod_storage()
	storage:set_string("networks", minetest.serialize(wireless))
end

local wireless_effector_off
local function remove_wireless(pos)
	local wls = moremesecons.get_data_from_pos(wireless_meta, pos)
	if not wls then
		return
	end

	if not wls.owner or wls.owner == "" then
		moremesecons.remove_data_from_pos(wireless_meta, pos)
		return
	end

	if not wireless[wls.owner] or not next(wireless[wls.owner]) then
		wireless[wls.owner] = nil
		moremesecons.remove_data_from_pos(wireless_meta, pos)
		return
	end

	if not wls.channel or wls.channel == "" then
		moremesecons.remove_data_from_pos(wireless_meta, pos)
		return
	end

	local network = wireless[wls.owner][wls.channel]

	if network.sources[wls.id] then
		wireless_effector_off(pos)
	end

	moremesecons.remove_data_from_pos(wireless_meta, pos)

	network.members[wls.id] = nil
	if not next(network.members) then
		wireless[wls.owner][wls.channel] = nil
		if not next(wireless[wls.owner]) then
			wireless[wls.owner] = nil
		end
	end
	update_mod_storage()
end

local function set_owner(pos, owner)
	if not owner or owner == "" then
		return
	end

	remove_wireless(pos)

	local meta = minetest.get_meta(pos)
	if meta then
		meta:set_string("owner", owner)
	end

	local wls = moremesecons.get_data_from_pos(wireless_meta, pos) or {}
	wls.owner = owner
	moremesecons.set_data_to_pos(wireless_meta, pos, wls)

	if not wireless[owner] then
		wireless[owner] = {}
	end

	if meta then
		meta:set_string("infotext", "Wireless owned by " .. owner .. " on " .. ((wls.channel and wls.channel ~= "") and "channel " .. wls.channel or "undefined channel"))
	end
end

local wireless_receptor_on
local wireless_receptor_off
local wireless_effector_on
local function set_channel(pos, channel)
	if not channel or channel == "" then
		return
	end

	local meta = minetest.get_meta(pos)

	local wls = moremesecons.get_data_from_pos(wireless_meta, pos)
	if not wls or wls.owner == "" then
		return
	end

	if wls.id then
		remove_wireless(pos)
	end

	if meta then
		meta:set_string("channel", channel)
	end
	wls.channel = channel
	moremesecons.set_data_to_pos(wireless_meta, pos, wls)

	if not wireless[wls.owner] then
		wireless[wls.owner] = {}
	end
	if not wireless[wls.owner][channel] then
		wireless[wls.owner][channel] = {
			members = {},
			sources = {}
		}
	end

	-- Find the first free ID
	local id = 1
	while wireless[wls.owner][channel].members[id] do
		id = id + 1
	end
	wls.id = id
	moremesecons.set_data_to_pos(wireless_meta, pos, wls)

	local network = wireless[wls.owner][channel]

	network.members[id] = pos

	if meta then
		meta:set_int("id", id)
	end

	update_mod_storage()

	if meta then
		meta:set_string("infotext", "Wireless owned by " .. wls.owner .. " on channel " .. channel)
	end

	if wls.effector then
		wireless_effector_on(pos)
	elseif next(network.sources) then
		wireless_receptor_on(pos, id, network, false)
	else
		wireless_receptor_off(pos, id, network, false)
	end
end

local function register_wireless(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner == "" then
		return
	end
	remove_wireless(pos)

	set_owner(pos, owner)

	local channel = meta:get_string("channel")
	if channel ~= "" then
		set_channel(pos, channel)
	end
end

local function check_wireless_exists(pos)
	local nn = minetest.get_node(pos).name
	if nn:sub(1, 30) == "moremesecons_wireless:wireless" then
		return true
	elseif nn ~= "ignore" then
		-- Defer the remove_wireless() call so it doesn't interfere
		-- with pairs().
		minetest.after(0, remove_wireless, pos)
		return false
	end
end

function wireless_receptor_on(pos, id, network, check)
	if check == false or check_wireless_exists(pos) then
		minetest.swap_node(pos, {name = "moremesecons_wireless:wireless_on"})
		if not network.sources[id] then
			mesecon.receptor_on(pos)
		end
	end
end

function wireless_receptor_off(pos, id, network, check)
	if check == false or check_wireless_exists(pos) then
		minetest.swap_node(pos, {name = "moremesecons_wireless:wireless_off"})
		mesecon.receptor_off(pos)
	end
end

local function activate_network(owner, channel)
	local network = wireless[owner][channel]
	for i, wl_pos in pairs(network.members) do
		wireless_receptor_on(wl_pos, i, network)
	end
end

local function deactivate_network(owner, channel)
	local network = wireless[owner][channel]
	for i, wl_pos in pairs(network.members) do
		wireless_receptor_off(wl_pos, i, network)
	end
end

local is_jammed
function wireless_effector_on(pos)
	if is_jammed(pos) then
		-- jamming doesn't disallow receiving signals, only sending them
		return
	end

	local wls = moremesecons.get_data_from_pos(wireless_meta, pos)
	if not wls then
		return
	end

	wls.effector = true

	moremesecons.set_data_to_pos(wireless_meta, pos, wls)

	if wls.owner == "" or not wireless[wls.owner] or wls.channel == "" or not wireless[wls.owner][wls.channel] then
		return
	end

	local network = wireless[wls.owner][wls.channel]
	network.sources[wls.id] = true
	activate_network(wls.owner, wls.channel)

	update_mod_storage()
end

function wireless_effector_off(pos)
	local wls = moremesecons.get_data_from_pos(wireless_meta, pos)
	if not wls then
		return
	end

	wls.effector = nil
	moremesecons.set_data_to_pos(wireless_meta, pos, wls)

	if wls.owner == "" or not wireless[wls.owner] or wls.channel == "" or not wireless[wls.owner][wls.channel] then
		return
	end

	local network = wireless[wls.owner][wls.channel]
	network.sources[wls.id] = nil
	if not next(network.sources) then
		deactivate_network(wls.owner, wls.channel)
	else
		-- There is another source in the network. Turn this wireless into
		-- a receptor.
		mesecon.receptor_on(pos)
	end

	update_mod_storage()
end

-- This table is required to prevent a message from being sent in loop between wireless nodes
local sending_digilines = {}

local function on_digiline_receive(pos, node, channel, msg)
	if is_jammed(pos) then
		return
	end

	local wls = moremesecons.get_data_from_pos(wireless_meta, pos)
	if not wls then
		return
	end

	if wls.owner == "" or not wireless[wls.owner] or channel == "" or not wireless[wls.owner][wls.channel] then
		return
	end

	local pos_hash = minetest.hash_node_position(pos)
	if sending_digilines[pos_hash] then
		return
	end

	sending_digilines[pos_hash] = true
	for i, wl_pos in pairs(wireless[wls.owner][wls.channel].members) do
		if i ~= wls.id then
			digiline:receptor_send(wl_pos, digiline.rules.default, channel, msg)
		end
	end
	sending_digilines[pos_hash] = nil
end

mesecon.register_node("moremesecons_wireless:wireless", {
	paramtype = "light",
	paramtype2 = "facedir",
	description = "Wireless",
	digiline = {
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		minetest.get_meta(pos):set_string("formspec", "field[channel;channel;${channel}]")
	end,
	on_destruct = function(pos)
		remove_wireless(pos)
		mesecon.receptor_off(pos)
	end,
	after_place_node = function(pos, placer)
		set_owner(pos, placer:get_player_name())
	end,
	on_receive_fields = function(pos, _, fields, player)
		local meta = minetest.get_meta(pos)
		local playername = player:get_player_name()

		local owner = meta:get_string("owner")
		if not owner or owner == "" then
			-- Old wireless
			if not minetest.is_protected(pos, playername) then
				set_owner(pos, playername)
			else
				return
			end
		end

		if playername == owner then
			set_channel(pos, fields.channel)
		end
	end,
}, {
	tiles = {"moremesecons_wireless_off.png"},
	groups = {cracky=3},
	mesecons = {effector = {
		action_on = wireless_effector_on
	}},
}, {
	tiles = {"moremesecons_wireless_on.png"},
	groups = {cracky=3, not_in_creative_inventory=1},
	mesecons = {effector = {
		action_off = wireless_effector_off
	}},
})

minetest.register_alias("moremesecons_wireless:wireless", "moremesecons_wireless:wireless_off")

minetest.register_craft({
	output = "moremesecons_wireless:wireless_off 2",
	recipe = {
		{"group:mesecon_conductor_craftable", "", "group:mesecon_conductor_craftable"},
		{"", "mesecons_torch:mesecon_torch_on", ""},
		{"group:mesecon_conductor_craftable", "", "group:mesecon_conductor_craftable"},
	}
})

local function remove_jammer(pos)
	moremesecons.remove_data_from_pos(jammers, pos)
end

local function add_jammer(pos)
	remove_jammer(pos)
	moremesecons.set_data_to_pos(jammers, pos, true)
end

function is_jammed(pos)
	local JAMMER_MAX_DISTANCE = moremesecons.setting("wireless", "jammer_max_distance", 15, 1)
	local JAMMER_MAX_DISTANCE_SQUARE = JAMMER_MAX_DISTANCE^2 -- Cache this result

	for pos_hash, _ in pairs(jammers.tab) do
		local j_pos = minetest.get_position_from_hash(pos_hash)
		-- Fast comparisons first
		if math.abs(pos.x - j_pos.x) <= JAMMER_MAX_DISTANCE and
				math.abs(pos.y - j_pos.y) <= JAMMER_MAX_DISTANCE and
				math.abs(pos.z - j_pos.z) <= JAMMER_MAX_DISTANCE and
				(pos.x - j_pos.x)^2 + (pos.y - j_pos.y)^2 + (pos.z - j_pos.z)^2 <= JAMMER_MAX_DISTANCE_SQUARE then
			return true
		end
	end

	return false
end

if moremesecons.setting("wireless", "enable_jammer", true) then
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
end

if moremesecons.setting("wireless", "enable_lbm", false) then
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
		action = register_wireless
	})
end

-- Legacy
if storage:get_string("wireless_meta_2") == "" then
	local wireless_meta_1 = minetest.deserialize(storage:get_string("wireless_meta"))
	if not wireless_meta_1 then
		return
	end

	minetest.log("action", "[moremesecons_wireless] Migrating mod storage data...")
	local jammers_1 = minetest.deserialize(storage:get_string("jammers"))

	local get = function(t, pos)
		-- FIXME: this does not test explicitly for false,
		-- but channel is never false
		return t[pos.z] and t[pos.z][pos.y] and t[pos.z][pos.y][pos.x]
	end

	for z, data_z in pairs(wireless_meta_1.owners) do
	for y, data_y in pairs(data_z) do
	for x, owner in pairs(data_y) do
		local pos = {x = x, y = y, z = z}
		set_owner(pos, owner)
		set_channel(pos, get(wireless_meta_1.channels, pos))
	end
	end
	end

	for z, data_z in pairs(jammers_1) do
	for y, data_y in pairs(data_z) do
	for x, jammer in pairs(data_y) do
		local pos = {x = x, y = y, z = z}
		moremesecons.set_data_to_pos(jammers, pos, jammer)
	end
	end
	end
	minetest.log("action", "[moremesecons_wireless] Done!")
end
