local JAMMER_MAX_DISTANCE = 10

-- see wireless jammer
local get = vector.get_data_from_pos
local set = vector.set_data_to_pos
local remove = vector.remove_data_from_pos

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

local function is_jammed(pos)
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

minetest.after(0, function() -- After load all mods, override some functions
	local current_pos

	local actual_node_get = minetest.get_node_or_nil
	local function temp_node_get(pos, ...)
		current_pos = pos
		return actual_node_get(pos, ...)
	end

	local actual_turnon = mesecon.turnon
	function mesecon.turnon(...)
		minetest.get_node_or_nil = temp_node_get
		--local v = actual_turnon(pos, ...)  commented because mesecon.turnon now doesn't return sth
		actual_turnon(...)
		minetest.get_node_or_nil = actual_node_get
		current_pos = nil
		--return v
	end

	local actual_is_conductor_off = mesecon.is_conductor_off
	function mesecon.is_conductor_off(...)
		if current_pos
		and is_jammed(current_pos) then
			return
		end
		return actual_is_conductor_off(...)
	end

	local actual_is_effector = mesecon.is_effector
	function mesecon.is_effector(...)
		if current_pos
		and is_jammed(current_pos) then
			return
		end
		return actual_is_effector(...)
	end
end)

mesecon.register_node("moremesecons_jammer:jammer", {
	description = "Mesecons Jammer",
	paramtype = "light",
},{
	tiles = {"moremesecons_jammer_off.png"},
	groups = {dig_immediate=2},
	mesecons = {effector = {
		action_on = function(pos)
			add_jammer(pos)
			minetest.swap_node(pos, {name="moremesecons_jammer:jammer_on"})
		end
	}},
},{
	tiles = {"moremesecons_jammer_on.png"},
	groups = {dig_immediate=2, not_in_creative_inventory=1},
	mesecons = {effector = {
		action_off = function(pos)
			remove_jammer(pos)
			minetest.swap_node(pos, {name="moremesecons_jammer:jammer_off"})
		end
	}},
	on_destruct = remove_jammer,
	on_construct = add_jammer,
})

minetest.register_craft({
	output = "moremesecons_jammer:jammer_off",
	recipe = {{"group:mesecon_conductor_craftable", "default:mese", "group:mesecon_conductor_craftable"},
		{"", "moremesecons_wireless:jammer_off", ""}}
})

minetest.register_abm({
	nodenames = {"moremesecons_jammer:jammer_on"},
	interval = 5,
	chance = 1,
	catch_up = false,
	action = add_jammer
})
