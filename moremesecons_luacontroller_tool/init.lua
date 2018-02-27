--[[
vector_extras there: https://github.com/HybridDog/vector_extras
]]

local templates = {MoreMesecons = {
	logic = [[-- AND
port.a = pin.b and pin.c
-- OR
port.a = pin.b or pin.c
-- NOT
port.a = not pin.b
-- NAND
port.a = not (pin.b and pin.c)
-- NOR
port.a = not (pin.b or pin.c)
-- XOR
port.a = pin.b ~= pin.c
-- XNOR / NXOR
port.a = pin.b == pin.c]],

	digilinesth = [[digiline_send(channel, msg)
if event.type == "digiline" then
	print(event.channel)
	print(event.msg)
end]],

	clock = [[number_of_oscillations = 0 -- 0 for infinity
interval = 1
input_port = "A"
output_port = "C"

if event.type == "on" and event.pin.name == input_port and not mem.running then
  if not mem.counter then
    mem.counter = 0
  end
  mem.running = true
  port[string.lower(output_port)] = true
  interrupt(interval)
  mem.counter = mem.counter + 1
elseif event.type == "off" and event.pin.name == input_port and mem.running and number_of_oscillations == 0 then
  mem.running = false
  mem.counter = 0
elseif event.type == "interrupt" then
  if not port[string.lower(output_port)] and mem.running then
    port[string.lower(output_port)] = true
    interrupt(interval)
    mem.counter = mem.counter + 1
  else
    port[string.lower(output_port)] = false
    if mem.counter < number_of_oscillations or number_of_oscillations == 0 and mem.running then
      interrupt(interval)
    else
      mem.running = false
      mem.counter = 0
    end
  end
end]],

	counter = [[counter_limit = 5
output_time = 0.5
input_port = "A"
output_port = "C"

if event.type == "on" and event.pin.name == input_port then
  if not mem.counter then
    mem.counter = 0
  end
  mem.counter = mem.counter + 1
  if mem.counter >= counter_limit then
     port[string.lower(output_port)] = true
     interrupt(output_time)
     mem.counter = 0
  end
elseif event.type == "interrupt" then
  port[string.lower(output_port)] = false
end]]
}}


local file_path = minetest.get_worldpath().."/MoreMesecons_lctt"

-- load templates from a compressed file
local templates_file = io.open(file_path, "rb")
if templates_file then
	local templates_raw = templates_file:read("*all")
	io.close(templates_file)
	if templates_raw
	and templates_raw ~= "" then
		for name,t in pairs(minetest.deserialize(minetest.decompress(templates_raw))) do
			templates[name] = t
		end
	end
end

-- the save function
local function save_to_file()
	local templates_file = io.open(file_path, "w")
	if not templates_file then
		minetest.log("error", "[MoreMesecons] Could not open file for saving!")
		return
	end
	local player_templates = table.copy(templates)
	player_templates.MoreMesecons = nil
	templates_file:write(minetest.compress(minetest.serialize(player_templates)))
	io.close(templates_file)
end

-- save doesn't save more than every 10s to disallow spamming
local saving
local function save()
	if saving then
		return
	end
	saving = true
	minetest.after(16, function()
		save_to_file()
		saving = false
	end)
end

minetest.register_on_shutdown(function()
	if saving then
		save_to_file()
	end
end)


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
	return txt..";"..(selected_id or 1).."]"
	--spec = string.sub(spec, 1, -2)
end

local pdata = {}

local function get_selection_formspec(pname, selected_template)
	-- templates might be removed by someone while changing sth in formspec
	local pl_templates = templates[pname]
	if not pl_templates then
		pname = next(templates)
		pl_templates = templates[pname]
	end

	local template_code = pl_templates[selected_template]
	if not template_code then
		selected_template = next(pl_templates)
		template_code = pl_templates[selected_template]
	end

	local spec = "size[10,10]"..

	-- show available players, field player_name, current player name is the selected one
		"dropdown[0,0;5;player_name;"..
		fill_formspec_dropdown_list(templates, pname)..

	-- show templates of pname
		"dropdown[5,0;5;template_name;"..
		fill_formspec_dropdown_list(pl_templates, selected_template)..

	-- show selected template
		"textarea[0,1;10.5,8.5;template_code;template code:;"..minetest.formspec_escape(template_code).."]"..

	-- save name
		"field[5,9.5;5,0;save_name;savename;"..selected_template.."]"..

		"button[0,10;2,0;button;set]"..

		"button[2,10;2,0;button;add]"..

		"button[5,10;2,0;button;save]"

	return spec
end

-- tests if the node is a luacontroller
local function is_luacontroller(pos)
	if not pos then
		return false
	end
	return string.match(minetest.get_node(pos).name, "mesecons_luacontroller:luacontroller%d%d%d%d")
end

-- do not localize the function directly here to support possible overwritten luacontrollers
local luac_def = minetest.registered_nodes["mesecons_luacontroller:luacontroller0000"]
local function set_luacontroller_code(pos, code, sender)
	luac_def.on_receive_fields(pos, nil, {code=code, program=""}, sender)
end

minetest.register_tool("moremesecons_luacontroller_tool:lctt", {
	description = "luacontroller template tool",
	inventory_image = "moremesecons_luacontroller_tool.png",

	on_use = function(_, player, pt)
		if not player
		or not pt then
			return
		end

		local pname = player:get_player_name()
		local pos = pt.under
		if not is_luacontroller(pos) then
			minetest.chat_send_player(pname, "You can use the luacontroller template tool only on luacontroller nodes.")
			return
		end

		pdata[pname] = {
			pos = pos,
			player_name = pname,
			template_name = pdata[pname] and pdata[pname].template_name or next(templates[pname] or templates[next(templates)]),
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

-- used to avoid possibly crashes
local function get_code_or_nil(pname, player_name, template_name)
	local player_templates = templates[player_name]
	if not player_templates then
		minetest.chat_send_player(pname, "error: "..player_name.." doesn't have templates now")
		return
	end
	local code = player_templates[template_name]
	if not code then
		minetest.chat_send_player(pname, "error: "..template_name.." doesn't exist now")
		return
	end
	return code
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "moremesecons:luacontroller_tool"
	or fields.quit
	or not player then
		return
	end

	--minetest.chat_send_all(dump(fields))

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
		local code = get_code_or_nil(pname, fields.player_name, fields.template_name)
		if code then
			set_luacontroller_code(pos, code, player)
			minetest.chat_send_player(pname, "code set to template at "..minetest.pos_to_string(pos))
		end
		return
	end

	if fields.button == "add" then
		-- add the template to the end of the code of the luacontroller
		local code = get_code_or_nil(pname, fields.player_name, fields.template_name)
		if code then
			set_luacontroller_code(pos, meta:get_string("code").."\r"..code, player)
			minetest.chat_send_player(pname, "code added to luacontroller at "..minetest.pos_to_string(pos))
		end
		return
	end

	if fields.button == "save" then
		-- save the template, when you try to change others' templates, yours become changed
		local savename = fields.template_name
		if fields.save_name
		and fields.save_name ~= ""
		and fields.save_name ~= savename then
			savename = minetest.formspec_escape(fields.save_name)
		end
		local code = fields.template_code
		if not code then
			minetest.chat_send_player(pname, "error: template code missing")
			return
		end
		templates[pname] = templates[pname] or {}
		if code == "" then
			templates[pname][savename] = nil
			if not next(templates[pname]) then
				templates[pname] = nil
			end
			minetest.chat_send_player(pname, "template removed")
			save()
			return
		end
		code = minetest.formspec_escape(code)
		if templates[pname][savename] == code then
			minetest.chat_send_player(pname, "template not saved because it didn't change")
			return
		end
		templates[pname][savename] = code
		save()
		minetest.chat_send_player(pname, "template "..pname.."/"..savename.." saved")
		return
	end
end)
