-- see wireless jammer
local storage = minetest.get_mod_storage()

local jammers = moremesecons.load_MapDataStorage_legacy(storage, "jammers_v2",
	"jammers")

local function update_mod_storage()
	storage:set_string("jammers_v2", jammers:serialize())
end

local function add_jammer(pos)
	if jammers:getAt(pos) then
		return
	end
	jammers:setAt(pos, true)
	update_mod_storage()
end

local function remove_jammer(pos)
	jammers:removeAt(pos)
	update_mod_storage()
end

local function is_jammed(pos)
	local JAMMER_MAX_DISTANCE = moremesecons.setting("jammer", "max_distance", 10, 1)

	local minp = vector.subtract(pos, JAMMER_MAX_DISTANCE)
	local maxp = vector.add(pos, JAMMER_MAX_DISTANCE)
	for p in jammers:iter(minp, maxp) do
		local d = vector.subtract(pos, p)
		if d.x ^ 2 + d.y ^ 2 + d.z ^ 2 <= JAMMER_MAX_DISTANCE^2 then
			return true
		end
	end
	return false
end

minetest.after(0, function() -- After loading all mods, override some functions
	local jammed

	local actual_node_get = mesecon.get_node_force
	local function temp_node_get(pos, ...)
		local node = actual_node_get(pos, ...)
		if jammed == nil
		and node then
			jammed = is_jammed(pos)
		end
		return node
	end

	local actual_is_conductor_off = mesecon.is_conductor_off
	local function temp_is_conductor_off(...)
		if jammed then
			-- go to the next elseif, there's is_effector
			return
		end
		local v = actual_is_conductor_off(...)
		if v then
			-- it continues to the next frontier
			jammed = nil
		end
		return v
	end

	local actual_is_effector = mesecon.is_effector
	local function temp_is_effector(...)
		local abort_here = jammed
		-- the last elseif before continuing, jammed needs to be nil then
		jammed = nil
		if abort_here then
			return
		end
		return actual_is_effector(...)
	end

	local actual_turnon = mesecon.turnon
	function mesecon.turnon(...)
		--set those to the temporary functions
		mesecon.get_node_force = temp_node_get
		mesecon.is_conductor_off = temp_is_conductor_off
		mesecon.is_effector = temp_is_effector

		actual_turnon(...)

		mesecon.get_node_force = actual_node_get
		mesecon.is_conductor_off = actual_is_conductor_off
		mesecon.is_effector = actual_is_effector

		-- safety
		jammed = nil
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
			minetest.sound_play("moremesecons_jammer", {pos = pos})
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

if moremesecons.setting("jammer", "enable_lbm", false) then
	minetest.register_lbm({
		name = "moremesecons_jammer:add_jammer",
		nodenames = {"moremesecons_jammer:jammer_on"},
		run_at_every_load = true,
		action = add_jammer
	})
end
