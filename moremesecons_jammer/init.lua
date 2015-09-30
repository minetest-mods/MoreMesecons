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

minetest.after(0, function() -- After load all mods
	function mesecon.turnon(pos, link) -- Overwrite mesecons function.
		local frontiers = {{pos = pos, link = link}}

		local depth = 1
		while frontiers[depth] do
			local f = frontiers[depth]
			local node = minetest.get_node_or_nil(f.pos)

			-- area not loaded, postpone action
			if not node then
				mesecon.queue:add_action(f.pos, "turnon", {link}, nil, true)
			elseif is_jammed(f.pos) then -- JAMMER
				return
			elseif mesecon.is_conductor_off(node, f.link) then
				local rules = mesecon.conductor_get_rules(node)

				minetest.swap_node(f.pos, {name = mesecon.get_conductor_on(node, f.link),
					param2 = node.param2})

				-- call turnon on neighbors: normal rules
				for _, r in ipairs(mesecon.rule2meta(f.link, rules)) do
					local np = mesecon.addPosRule(f.pos, r)

					-- area not loaded, postpone action
					if not minetest.get_node_or_nil(np) then
						mesecon.queue:add_action(np, "turnon", {rulename},
							nil, true)
					else
						local links = mesecon.rules_link_rule_all(f.pos, r)
						for _, l in ipairs(links) do
							table.insert(frontiers, {pos = np, link = l})
						end
					end
				end
			elseif mesecon.is_effector(node.name) then
				mesecon.changesignal(f.pos, node, f.link, mesecon.state.on, depth)
				if mesecon.is_effector_off(node.name) then
					mesecon.activate(f.pos, node, f.link, depth)
				end
			end
			depth = depth + 1
		end
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
	action = add_jammer
})
