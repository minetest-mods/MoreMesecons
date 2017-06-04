local use_speech_dispatcher = moremesecons.setting("sayer", "use_speech_dispatcher", true)

local popen, execute = io.popen, os.execute
if use_speech_dispatcher then
	if not minetest.is_singleplayer() then
		minetest.log("warning", "[moremesecons_sayer] use_speech_dispatcher = true, but the speech dispatcher can only be used in singleplayer")
		use_speech_dispatcher = false
	else
		local ie = {}
		if minetest.request_insecure_environment then
			ie = minetest.request_insecure_environment()
		end
		if not ie then
			minetest.log("warning", "[moremesecons_sayer] This mod needs access to insecure functions in order to use the speech dispatcher. Please add the moremesecons_sayer mod to your secure.trusted_mods settings or disable the speech dispatcher.")
			use_speech_dispatcher = false
		else
			popen = ie.io.popen
			execute = ie.os.execute
		end
	end

	if use_speech_dispatcher then
		if popen("if hash spd-say 2>/dev/null; then printf yes; fi"):read("*all") ~= "yes" then
			minetest.log("warning", "[moremesecons_sayer] use_speech_dispatcher = true, but it seems the speech dispatcher isn't installed on your system")
			use_speech_dispatcher = false
		end
	end
end

local sayer_activate
if use_speech_dispatcher then
	minetest.log("info", "[moremesecons_sayer] using speech dispatcher")
	local tab = {
		"spd-say",
		nil,
		""
	}
	local language = minetest.settings:get("language") or "en"
	if language ~= "en" then
		tab[3] = "-l "..language
	end

	function sayer_activate(pos)
		local MAX_DISTANCE = moremesecons.setting("sayer", "max_distance", 8, 1) ^ 2

		local text = minetest.get_meta(pos):get_string("text")
		if text == "" then
			-- nothing to say
			return
		end
		if string.find(text, '"') then
			text = "So, singleplayer, you want to use me to execute commands? Writing quotes is not allowed!"
		end
		tab[2] = '"'..text..'"'
		local ppos = minetest.get_player_by_name("singleplayer"):getpos()
		ppos.y = ppos.y+1.625 -- camera position (without bobbing)
		-- that here's just 1 volume means that it's mono
		local volume = math.floor(-100*(
			1-MAX_DISTANCE/vector.distance(pos, ppos)^2
		+0.5))
		if volume <= -100 then
			-- nothing to hear
			return
		end
		if volume > 0 then
			--volume = "+"..math.min(100, volume)
			-- volume bigger 0 somehow isn't louder, it rather tries to scream
			volume = "+"..math.min(100, math.floor(volume/(MAX_DISTANCE-1)+0.5))
		end
		if volume == 0 then
			tab[4] = nil
		else
			tab[4] = "-i "..volume
		end
		execute(table.concat(tab, " "))
	end
else
	function sayer_activate(pos)
		local MAX_DISTANCE = moremesecons.setting("sayer", "max_distance", 8, 1)

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
	on_receive_fields = function(pos, _, fields, player)
		if fields.text
		and not minetest.is_protected(pos, player:get_player_name()) then
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
