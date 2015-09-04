local MAX_DISTANCE = 8

local function sayer_activate(pos)
	local tab = {
		"Sayer at pos",
		nil,
		"says : "..minetest.get_meta(pos):get_string("text")
	}
	for _,player in pairs(minetest.get_connected_players()) do
		if vector.distance(pos, player:getpos()) <= MAX_DISTANCE then
			tab[2] = minetest.pos_to_string(pos)
			minetest.chat_send_player(player:get_player_name(), table.concat(tab, " "))
		end
	end
end

minetest.register_node("moremesecons_sayer:sayer", {
	description = "sayer",
	tiles = {"mesecons_noteblock.png", "default_wood.png"},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	groups = {dig_immediate = 2},
	on_construct = function(pos)
   		minetest.get_meta(pos):set_string("formspec", "field[text;text;${text}]")
	end,
	on_receive_fields = function(pos, _, fields)
		if fields.text then
			minetest.get_meta(pos):set_string("text", fields.text)
		end
	end,
	mesecons = {effector = {
		action_on = sayer_activate
	}}
})

minetest.register_craft({
	output = "moremesecons_sayer:sayer 2",
	recipe = {{"mesecons_luacontroller:luacontroller0000", "mesecons_noteblock:noteblock"},
		{"group:wood", "group:wood"}}
})
