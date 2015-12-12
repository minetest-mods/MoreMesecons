local function add_back_igniter(pos)
	local name = minetest.get_node(pos).name

	if name == "moremesecons_igniter:igniter" then
		-- this should not happen
		minetest.log("error", "[moremesecons_igniter] igniter is already back")
		return
	end

	if name == "ignore" then
		-- in case of unloaded chunk
		minetest.get_voxel_manip():read_from_map(pos, pos)
		name = minetest.get_node(pos).name
	end

	if name == "air"
	or name == "fire:basic_flame" then
		minetest.set_node(pos, {name="moremesecons_igniter:igniter"})
	else
		-- drop it as item if something took place there in the 0.8 seconds
		pos.y = pos.y+1
		minetest.add_item(pos, "moremesecons_igniter:igniter")
		pos.y = pos.y-1
	end
end

local function igniter_on(pos)
	minetest.set_node(pos, {name="fire:basic_flame"})
	minetest.after(0.8, add_back_igniter, pos)
end

minetest.register_node("moremesecons_igniter:igniter", {
	description = "Igniter",
	paramtype = "light",
	tiles = {"moremesecons_igniter.png"},
	groups = {cracky=3},
	mesecons = {
		effector = {
			action_on = igniter_on
	}}
})


minetest.register_craft({
	output = "moremesecons_igniter:igniter",
	recipe = {	{"default:torch"},
			{"default:mese_crystal_fragment"},}
})
