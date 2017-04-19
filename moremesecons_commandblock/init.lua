local function initialize_data(meta)
	local NEAREST_MAX_DISTANCE = moremesecons.setting("commandblock", "nearest_max_distance", 8, 1)

	local commands = meta:get_string("commands")
	meta:set_string("formspec",
		"invsize[9,5;]" ..
		"textarea[0.5,0.5;8.5,4;commands;Commands;"..commands.."]" ..
		"label[1,3.8;@nearest is replaced by the nearest player name ("..tostring(NEAREST_MAX_DISTANCE).." nodes max for the nearest distance)".."]" ..
		"button_exit[3.3,4.5;2,1;submit;Submit]")
	local owner = meta:get_string("owner")
	if owner == "" then
		owner = "not owned"
	else
		owner = "owned by " .. owner
	end
	meta:set_string("infotext", "Command Block\n" ..
		"(" .. owner .. ")\n" ..
		"Commands: "..commands)
end

local function construct(pos)
	local meta = minetest.get_meta(pos)

	meta:set_string("commands", "tell @nearest Commandblock unconfigured")

	meta:set_string("owner", "")

	initialize_data(meta)
end

local function after_place(pos, placer)
	if placer then
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		initialize_data(meta)
	end
end

local function receive_fields(pos, _, fields, player)
	if not fields.submit then
		return
	end
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner ~= ""
	and player:get_player_name() ~= owner then
		return
	end
	meta:set_string("commands", fields.commands)

	initialize_data(meta)
end

local function resolve_commands(commands, pos)
	local nearest = nil
	local min_distance = math.huge
	local players = minetest.get_connected_players()
	for index, player in pairs(players) do
		local distance = vector.distance(pos, player:getpos())
		if distance < min_distance then
			min_distance = distance
			nearest = player:get_player_name()
		end
	end
	new_commands = commands:gsub("@nearest", nearest)
	return new_commands, min_distance, new_commands ~= commands
end

local function commandblock_action_on(pos, node)
	local NEAREST_MAX_DISTANCE = moremesecons.setting("commandblock", "nearest_max_distance", 8, 1)

	local accepted_commands = {}
	do
		local commands_str = moremesecons.setting("commandblock", "authorized_commands", "tell")
		for command in string.gmatch(commands_str, "([^ ]+)") do
			accepted_commands[command] = true
		end
	end

	if node.name ~= "moremesecons_commandblock:commandblock_off" then
		return
	end

	minetest.swap_node(pos, {name = "moremesecons_commandblock:commandblock_on"})

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner == "" then
		return
	end

	local commands, distance, nearest_in_commands = resolve_commands(meta:get_string("commands"), pos)
	if distance > NEAREST_MAX_DISTANCE and nearest_in_commands then
		minetest.chat_send_player(owner, "The nearest player is too far to use his name in the commands of a craftable command block.")
		return
	end
	for _, command in pairs(commands:split("\n")) do
		local pos = command:find(" ")
		local cmd, param = command, ""
		if pos then
			cmd = command:sub(1, pos - 1)
			param = command:sub(pos + 1)
		end
		local cmddef = minetest.chatcommands[cmd]
		if not accepted_commands[cmd] and next(accepted_commands) then
			minetest.chat_send_player(owner, "You can not execute the command "..cmd.." with a craftable command block ! This event will be reported.")
			minetest.log("action", "Player "..owner.." tryed to execute an unauthorized command with a craftable command block.")
			return
		end
		if not cmddef then
			minetest.chat_send_player(owner, "The command "..cmd.." does not exist")
			return
		end
		local has_privs, missing_privs = minetest.check_player_privs(owner, cmddef.privs)
		if not has_privs then
			minetest.chat_send_player(owner, "You don't have permission "
					.."to run "..cmd
					.." (missing privileges: "
					..table.concat(missing_privs, ", ")..")")
			return
		end
		cmddef.func(owner, param)
	end
end

local function commandblock_action_off(pos, node)
	if node.name == "moremesecons_commandblock:commandblock_on" then
		minetest.swap_node(pos, {name = "moremesecons_commandblock:commandblock_off"})
	end
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	return owner == "" or owner == player:get_player_name()
end

minetest.register_node("moremesecons_commandblock:commandblock_off", {
	description = "Craftable Command Block",
	tiles = {"moremesecons_commandblock_off.png"},
	groups = {cracky=2, mesecon_effector_off=1},
	on_construct = construct,
	after_place_node = after_place,
	on_receive_fields = receive_fields,
	can_dig = can_dig,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {effector = {
		action_on = commandblock_action_on
	}}
})

minetest.register_node("moremesecons_commandblock:commandblock_on", {
	tiles = {"moremesecons_commandblock_on.png"},
	groups = {cracky=2, mesecon_effector_on=1, not_in_creative_inventory=1},
	light_source = 10,
	drop = "moremesecons_commandblock:commandblock_off",
	on_construct = construct,
	after_place_node = after_place,
	on_receive_fields = receive_fields,
	can_dig = can_dig,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {effector = {
		action_off = commandblock_action_off
	}}
})

minetest.register_craft({
	output = "moremesecons_commandblock:commandblock_off",
	recipe = {
		{"group:mesecon_conductor_craftable","default:mese_crystal","group:mesecon_conductor_craftable"},
		{"default:mese_crystal","group:mesecon_conductor_craftable","default:mese_crystal"},
		{"group:mesecon_conductor_craftable","default:mese_crystal","group:mesecon_conductor_craftable"}
	}
})
