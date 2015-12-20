local templates = {
	singleplayer = {fir = "daw", mak = "delay()"},
	["MoreMesecons"] = {mag = "dawasd", mak = "delrq"},
}

-- when adding templates minetest.formspec_escape(string) should be used, even for the names
-- this way it doesn't work for multiplayer (missing tests at receiving)
-- formspec, saving etc. is unfinished

-- used for the dropdown formspec element
local function fill_formspec_dropdown_list(t, selected)
	local it,num = {},1
	for i in pairs(t) do
		it[num] = i
		num = num+1
	end
	num = num-1
	table.sort(it)
	local txt = ""
	local selected_id
	for i = 1,num do
		local t = it[i]
		if not selected_id
		and t == selected then
			selected_id = i
		end
		txt = txt..t -- add available indices
		if i ~= num then
			txt = txt..","
		end
	end
	return txt..";"..selected_id.."]"
	--spec = string.sub(spec, 1, -2)
end

local pdata = {}

local function get_selection_formspec(pname, selected_template)
	local spec = "size[10,10]"..

	-- show available players, field player_name, current player name is the selected one
		"dropdown[0,0;3;player_name;"..
		fill_formspec_dropdown_list(templates, pname)..

	-- show templates of pname
		"dropdown[0,1;3;template_name;"..
		fill_formspec_dropdown_list(templates[pname], selected_template)..

	-- show selected template
		"textarea[0,4;7,7;template_code;template code:;"..templates[pname][selected_template].."]"..

		"button[0,2;1,1;button;set]"..

		"button[1,2;1,1;button;add]"..

		"button[2,2;1,1;button;save]"

	return spec
end

-- tests if the node is a luacontroller
local function is_luacontroller(pos)
	return string.match(minetest.get_node(pos).name, "mesecons_luacontroller:luacontroller%d%d%d%d")
end

-- do not localize the function directly here to support possible overwritten luacontrollers
local luac_def = minetest.registered_nodes["mesecons_luacontroller:luacontroller0000"]
local function set_luacontroller_code(pos, code)
	luac_def.on_receive_fields(pos, nil, {code=code, program=""})
end

minetest.register_tool("moremesecons_luacontroller_tool:luacontroller_template_tool", {
	description = "luacontroller template tool",
	inventory_image = "moremesecons_luacontroller_tool.png",

	on_place = function(itemstack, player, pt)
		if not player
		or not pt then
			return
		end

		local pos = pt.under
		if not is_luacontroller(pos) then
			return
		end

		local pname = player:get_player_name()
		pdata[pname] = pdata[pname] or {
			pos = pos,
			player_name = pname,
			template_name = next(templates[pname]),
		}
		minetest.show_formspec(pname, "moremesecons:luacontroller_tool", get_selection_formspec(pdata[pname].player_name, pdata[pname].template_name))


	end,
})

--[[ Luacontroller reset_meta function, by Jeija
local function reset_meta(pos, code, errmsg)
	local meta = minetest.get_meta(pos)
	meta:set_string("code", code)
	code = minetest.formspec_escape(code or "")
	errmsg = minetest.formspec_escape(errmsg or "")
	meta:set_string("formspec", "size[10,8]"..
		"background[-0.2,-0.25;10.4,8.75;jeija_luac_background.png]"..
		"textarea[0.2,0.6;10.2,5;code;;"..code.."]"..
		"image_button[3.75,6;2.5,1;jeija_luac_runbutton.png;program;]"..
		"image_button_exit[9.72,-0.25;0.425,0.4;jeija_close_window.png;exit;]"..
		"label[0.1,5;"..errmsg.."]")
	meta:set_int("heat", 0)
	meta:set_int("luac_id", math.random(1, 65535))
end--]]

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "moremesecons:luacontroller_tool"
	or fields.quit
	or not player then
		return
	end

	minetest.chat_send_all(dump(fields))

	local pname = player:get_player_name()

	if fields.player_name
	and fields.player_name ~= pdata[pname].player_name then
		-- show available templates of that player
		minetest.show_formspec(pname, "moremesecons:luacontroller_tool",
			get_selection_formspec(fields.player_name, pdata[pname].template_name)
		)
		pdata[pname].player_name = fields.player_name
		return
	end

	if fields.template_name
	and fields.template_name ~= pdata[pname].template_name then
		-- show selected template of that player
		minetest.show_formspec(pname, "moremesecons:luacontroller_tool",
			get_selection_formspec(pdata[pname].player_name, fields.template_name)
		)
		pdata[pname].template_name = fields.template_name
		return
	end

	local pos = pdata[pname].pos
	if not is_luacontroller(pos) then
		-- this can happen
		return
	end

	local meta = minetest.get_meta(pos)

	if fields.button == "set" then
		-- replace the code of the luacontroller with the template
		set_luacontroller_code(pos, templates[fields.player_name][fields.template_name])
		minetest.chat_send_player(pname, "code set to template at "..vector.pos_to_string(pos))
		return
	end

	if fields.button == "add" then
		-- add the template to the end of the code of the luacontroller
		set_luacontroller_code(pos, meta:get_string("code").."\r"..templates[fields.player_name][fields.template_name])
		minetest.chat_send_player(pname, "code added to luacontroller at "..vector.pos_to_string(pos))
		return
	end

	if fields.button == "save" then
		-- save the template, when you try to change others' templates, yours become changed
		local savename = fields.save_name or fields.template_name
		local code = fields.template_code or templates[fields.player_name][fields.template_name]
		--[[
		if not code then
			minetest.chat_send_player(pname, "you can't save if you didn't change the code")
			return
		end--]]
		local template_name = savename
		templates[pname][template_name] = code
		minetest.chat_send_player(pname, "template "..pname.."/"..template_name.." saved")
		return
	end
end)
