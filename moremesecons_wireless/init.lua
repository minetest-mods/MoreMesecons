local storage = minetest.get_mod_storage()

local wireless = minetest.deserialize(storage:get_string("wireless")) or {}
local wireless_meta = minetest.deserialize(storage:get_string("wireless_meta")) or {owners = {}, channels = {}, ids = {}}
local jammers = minetest.deserialize(storage:get_string("jammers")) or {}

local function update_mod_storage()
	storage:set_string("wireless", minetest.serialize(wireless))
	storage:set_string("wireless_meta", minetest.serialize(wireless_meta))
	storage:set_string("jammers", minetest.serialize(jammers))
end

-- localize these functions with small names because they work fairly fast
local get = vector.get_data_from_pos
local set = vector.set_data_to_pos
local remove = vector.remove_data_from_pos

local function remove_wireless(pos)
	local owner = get(wireless_meta.owners, pos.z,pos.y,pos.x)
	if not owner or owner == "" then
		return
	end
	remove(wireless_meta.owners, pos.z,pos.y,pos.x)
	if not wireless[owner] or not next(wireless[owner]) then
		wireless[owner] = nil
		return
	end

	local channel = get(wireless_meta.channels, pos.z,pos.y,pos.x)
	if not channel or channel == "" then
		return
	end

	table.remove(wireless[owner][channel], get(wireless_meta.ids, pos.z,pos.y,pos.x))
	if #wireless[owner][channel] == 0 then
		wireless[owner][channel] = nil
		if not next(wireless[owner]) then
			wireless[owner] = nil
		end
	end

	remove(wireless_meta.channels, pos.z,pos.y,pos.x)
	remove(wireless_meta.ids, pos.z,pos.y,pos.x)
end

local set_channel
local function set_owner(pos, owner)
	if not owner or owner == "" then
		return
	end
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", owner)
	set(wireless_meta.owners, pos.z,pos.y,pos.x, owner)
	if not wireless[owner] then
		wireless[owner] = {}
	end

	local channel = get(wireless_meta.channels, pos.z,pos.y,pos.x)
	if channel and channel ~= "" then
		if not wireless[owner][channel] then
			wireless[owner][channel] = {}
		end
		set_channel(pos, channel)
	end

	meta:set_string("infotext", "Wireless owned by " .. owner .. " on " .. ((channel and channel ~= "") and "channel " .. channel or "undefined channel"))
end

function set_channel(pos, channel)
	if not channel or channel == "" then
		return
	end

	local meta = minetest.get_meta(pos)
	local owner = get(wireless_meta.owners, pos.z,pos.y,pos.x)
	if not owner or owner == "" then
		return
	end

	local old_channel = get(wireless_meta.channels, pos.z,pos.y,pos.x)
	if old_channel and old_channel ~= "" and old_channel ~= channel then
		remove_wireless(pos)
		set_owner(pos, owner)
	end

	meta:set_string("channel", channel)
	set(wireless_meta.channels, pos.z,pos.y,pos.x, channel)
	if not wireless[owner] then
		wireless[owner] = {}
	end
	if not wireless[owner][channel] then
		wireless[owner][channel] = {}
	end

	local id = get(wireless_meta.ids, pos.z,pos.y,pos.x)
	if id then
		wireless[owner][channel][id] = pos
	else
		table.insert(wireless[owner][channel], pos)
		meta:set_int("id", #wireless[owner][channel])
		set(wireless_meta.ids, pos.z,pos.y,pos.x, #wireless[owner][channel])
	end

	meta:set_string("infotext", "Wireless owned by " .. owner .. " on channel " .. channel)
end

local function register_wireless(pos)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner == "" then
		return
	end
	set_owner(pos, owner)

	local channel = meta:get_string("channel")
	if channel ~= "" then
		set_channel(pos, channel)
	end

	update_mod_storage()
end

local is_jammed
local function wireless_activate(pos)
	if is_jammed(pos) then
		-- jamming doesn't disallow receiving signals, only sending them
		return
	end

	local channel = get(wireless_meta.channels, pos.z,pos.y,pos.x)
	local owner = get(wireless_meta.owners, pos.z,pos.y,pos.x)
	local id = get(wireless_meta.ids, pos.z,pos.y,pos.x)

	if owner == "" or not wireless[owner] or channel == "" or not wireless[owner][channel] then
		return
	end

	minetest.swap_node(pos, {name = "moremesecons_wireless:wireless_on"})
	for i, wl_pos in ipairs(wireless[owner][channel]) do
		if i ~= id then
			minetest.swap_node(wl_pos, {name = "moremesecons_wireless:wireless_on"})
			mesecon.receptor_on(wl_pos)
		end
	end
end

local function wireless_deactivate(pos)
	if is_jammed(pos) then
		return
	end

	local channel = get(wireless_meta.channels, pos.z,pos.y,pos.x)
	local owner = get(wireless_meta.owners, pos.z,pos.y,pos.x)
	local id = get(wireless_meta.ids, pos.z,pos.y,pos.x)

	if owner == "" or not wireless[owner] or channel == "" or not wireless[owner][channel] then
		return
	end

	minetest.swap_node(pos, {name = "moremesecons_wireless:wireless_off"})
	for i, wl_pos in ipairs(wireless[owner][channel]) do
		if i ~= id then
			minetest.swap_node(wl_pos, {name = "moremesecons_wireless:wireless_off"})
			mesecon.receptor_off(wl_pos)
		end
	end
end

local function on_digiline_receive(pos, node, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel") -- Note : the digiline channel is the same as the wireless channel. TODO: Making two different channels and a more complex formspec ?
	if channel ~= setchan or is_jammed(pos) or setchan == "" then
		return
	end

	local channel = get(wireless_meta.channels, pos.z,pos.y,pos.x)
	local owner = get(wireless_meta.owners, pos.z,pos.y,pos.x)
	local id = get(wireless_meta.ids, pos.z,pos.y,pos.x)

	if owner == "" or not wireless[owner] or channel == "" or not wireless[owner][channel] then
		return
	end

	for i, wl_pos in ipairs(wireless[owner][channel]) do
		if i ~= id then
			digiline:receptor_send(wl_pos, digiline.rules.default, channel, msg)
		end
	end
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
		update_mod_storage()
		mesecon.receptor_off(pos)
	end,
	after_place_node = function(pos, placer)
		local placername = placer:get_player_name()
		set_owner(pos, placer:get_player_name())
		update_mod_storage()
	end,
	on_receive_fields = function(pos, _, fields, player)
		local meta = minetest.get_meta(pos)
		local playername = player:get_player_name()

		local owner = meta:get_string("owner")
		if not owner or owner == "" then
			-- Old wireless
			if not minetest.is_protected(pos, playername) then
				set_owner(pos, playername)
				update_mod_storage()
			else
				return
			end
		end

		if playername == owner then
			set_channel(pos, fields.channel)
			update_mod_storage()
		end
	end,
}, {
	tiles = {"moremesecons_wireless_off.png"},
	groups = {cracky=3},
	mesecons = {effector = {
		action_on = wireless_activate,
	}},
}, {
	tiles = {"moremesecons_wireless_on.png"},
	groups = {cracky=3, not_in_creative_inventory=1},
	mesecons = {effector = {
		action_off = wireless_deactivate
	}},
})

minetest.register_alias("moremesecons_wireless:wireless", "moremesecons_wireless:wireless_off")

local jammers = {}
local function add_jammer(pos)
	if get(jammers, pos.z,pos.y,pos.x) then
		return
	end
	set(jammers, pos.z,pos.y,pos.x, true)
	update_mod_storage()
end

local function remove_jammer(pos)
	remove(jammers, pos.z,pos.y,pos.x)
	update_mod_storage()
end

-- looks big, but should work fast
function is_jammed(pos)
	local JAMMER_MAX_DISTANCE = moremesecons.setting("wireless", "jammer_max_distance", 15, 1)

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
	output = "moremesecons_wireless:wireless_off 2",
	recipe = {
		{"group:mesecon_conductor_craftable", "", "group:mesecon_conductor_craftable"},
		{"", "mesecons_torch:mesecon_torch_on", ""},
		{"group:mesecon_conductor_craftable", "", "group:mesecon_conductor_craftable"},
	}
})

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
if storage and storage:get_string("wireless_rids") and storage:get_string("wireless_rids") ~= "" then
	-- Upgrade mod storage!
	local wireless_rids = minetest.deserialize(storage:get_string("wireless_rids"))
	local old_wireless = table.copy(wireless)
	wireless = {}

	minetest.after(0, function(old_wireless)
		-- After loading all mods, try to guess owners based on the areas mod database.
		-- That won't work for all wireless. Owners of remaining wireless will be set
		-- to the first player using their formspec.
		if not areas then
			return
		end
		for RID, pos in ipairs(old_wireless) do
			local numerous_owners = false
			local owner
			for _, area in pairs(areas:getAreasAtPos(pos)) do
				if owner and area.owner ~= owner then
					numerous_owners = true
					break
				end
				owner = area.owner
			end

			if not numerous_owners and owner then
				set_owner(pos, owner)
				set_channel(pos, minetest.get_meta(pos):get_string("channel"))
			end
		end
	end, old_wireless)

	-- Remove wireless_rids from storage
	storage:from_table({
		jammers = jammers,
		wireless_meta = wireless_meta,
		wireless = wireless
	})
end
