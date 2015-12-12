local function igniter_on(pos)
	local fire_node = {name="fire:basic_flame"}
	local igniter_node = {name="moremesecons_igniter:igniter"}
	minetest.set_node(pos, fire_node)
	minetest.after(0.8, minetest.set_node, pos, igniter_node)
end

minetest.register_node("moremesecons_igniter:igniter", {
	description="Igniter",
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
