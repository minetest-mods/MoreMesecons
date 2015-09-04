local MAX_DISTANCE = 8

local sayer_activate = function(pos)
	local players = minetest.get_connected_players()
	local text = minetest.get_meta(pos):get_string("text")
	for index, player in pairs(players) do
		local distance = vector.distance(pos, player:getpos())
		if distance <= MAX_DISTANCE then
			minetest.chat_send_player(player:get_player_name(), "Sayer at pos "
						..tostring(pos.x)..","
						..tostring(pos.y)..","
						..tostring(pos.z)
						.." says : "
						..text)
		end
	end
end

minetest.register_node("moremesecons_sayer:sayer", {
	description = "sayer",
	tiles = {"mesecons_noteblock.png", "default_wood.png", "default_wood.png", "default_wood.png", "default_wood.png", "default_wood.png"},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
	groups = {dig_immediate = 2},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
   		meta:set_string("formspec", "field[text;text;${text}]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		meta:set_string("text", fields.text)
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
