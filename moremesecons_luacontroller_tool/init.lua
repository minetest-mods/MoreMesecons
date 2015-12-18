local templates = {
	singleplayer = {fir = "daw", mak = "delay()"},
}

-- when adding templates minetest.formspec_escape(string) should be used, even for the names
-- this way it doesn't work for multiplayer (missing tests at receiving)
-- formspec, luacontroller identification, saving etc. is unfinished

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
	for i = 1,num do
		txt = txt..i -- add available indices
		if i ~= num then
			txt = txt..","
		end
	end
	return txt
	--spec = string.sub(spec, 1, -2)
end

local pdata = {}

local function get_selection_formspec(pname, selected_template)
	-- current player name
	pname = pname or pdata[pname].player_name
	selected_template = selected_template or pdata[pname].template_name
	local spec = "size[3,1]"..

	-- show available players, field player_name, current player name is the selected one
		"dropdown[0,0;3,1;player_name;"..
		fill_formspec_dropdown_list(templates, pname)..
		";"..pname.."]"..

	-- show templates of pname
		"dropdown[0,1;3,1;template_name;"..
		fill_formspec_dropdown_list(templates[pname], selected_template)..
		";"..selected_template.."]"..

	-- show selected template
		"multiline["..templates[pname][selected_template]..

		buttonset..

		buttonadd..

		buttonsave

	return spec
end

local function is_luacontroller(pos)
		local node = minetest.get_node(pos)
		if node.name ~= ":luacontroller" then
			return false
		end

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
		pdata[pname] = {
			pos = pos,
			player_name = pname,
			template_name = next(templates[pname]),
		}
		minetest.show_formspec(pname, "moremesecons:luacontroller_tool", spec)


	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "moremesecons:luacontroller_tool"
	or fields.quit
	or not player then
		return
	end

	local pname = player:get_player_name()

	if fields.player_name then
		-- show available templates of that player
		minetest.show_formspec(pname, "moremesecons:luacontroller_tool",
			get_selection_formspec(fields.player_name)
		)
		pdata[pname].player_name = fields.player_name
		return
	end

	if fields.template_name then
		-- show selected template of that player
		minetest.show_formspec(pname, "moremesecons:luacontroller_tool",
			get_selection_formspec(nil, fields.template_name)
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

	if fields.set then
		-- replace the code of the luacontroller with the template
		meta:set_string("code", templates[pdata[pname].player_name][pdata[pname].template_name])
		minetest.chat_send_player(pname, "code set to template at "..vector.pos_to_string(pos))
		return
	end

	if fields.add then
		-- add the template to the end of the code of the luacontroller
		meta:set_string("code", meta:get_string("code")..templates[pdata[pname].player_name][pdata[pname].template_name])
		minetest.chat_send_player(pname, "code added to luacontroller at "..vector.pos_to_string(pos))
		return
	end

	if fields.save then
		-- save the template, when you try to change others' templates, yours become changed
		local savename = fields.save_name or pdata[pname].template_name
		local code = fields.template_code or templates[pdata[pname].player_name][pdata[pname].template_name]
		--[[
		if not code then
			minetest.chat_send_player(pname, "you can't save if you didn't change the code")
			return
		end--]]
		local template_name = pdata[pname].template_name
		templates[pname][template_name] = code
		minetest.chat_send_player(pname, "template "..pname.."/"..template_name.." saved")
		return
	end
end)
