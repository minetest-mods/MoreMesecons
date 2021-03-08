local storage = minetest.get_mod_storage()
local pos_data = moremesecons.get_storage_data(storage, "pos_data")

local function set_data(pos, code, owner)
	local data = {
		code = code,
		owner = owner
	}
	moremesecons.set_data_to_pos(pos_data, pos, data)
end

local function check_data(pos, code, owner)
	local stored_data = moremesecons.get_data_from_pos(pos_data, pos)
	if not stored_data then
		return false
	end
	if code ~= stored_data.code
			or owner ~= stored_data.owner then
		return false
	end
	return true
end


local function make_formspec(meta, pos)
	local code = minetest.formspec_escape(meta:get_string("code"))
	local errmsg = minetest.formspec_escape(meta:get_string("errmsg"))
	meta:set_string("formspec",
		"size[10,8;]" ..
		"textarea[0.5,0.5;9.5,7;code;Code;"..code.."]" ..
		"label[0.1,7;"..errmsg.."]" ..
		"button_exit[4,7.5;2,1;submit;Submit]")
end

minetest.register_node("moremesecons_luablock:luablock", {
	description = "Lua Block",
	tiles =  {"moremesecons_luablock.png"},
	groups = {cracky = 2},
	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		if udef and udef.on_rightclick and
				not (placer and placer:get_player_control().sneak) then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end

		local pos
		if minetest.registered_items[minetest.get_node(under).name].buildable_to then
			pos = under
		else
			pos = pointed_thing.above
		end

		local name = placer:get_player_name()
		if minetest.is_protected(pos, name) and
				not minetest.check_player_privs(name, {protection_bypass = true}) then
			minetest.record_protection_violation(pos, name)
			return itemstack
		end
		if not minetest.check_player_privs(name, {server = true}) then
			minetest.chat_send_player(name, "You can't use a LuaBlock without the server privilege.")
			return itemstack
		end

		local node_def = minetest.registered_nodes[minetest.get_node(pos).name]
		if not node_def or not node_def.buildable_to then
			return itemstack
		end

		minetest.set_node(pos, {name = "moremesecons_luablock:luablock"})

		local meta = minetest.get_meta(pos)
		meta:set_string("owner", name)
		meta:set_string("infotext", "LuaBlock owned by " .. name)
		make_formspec(meta, pos)

		if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(placer:get_player_name())) then
			itemstack:take_item()
		end
		return itemstack
	end,
	on_receive_fields = function(pos, form_name, fields, sender)
		if not fields.submit then
			return
		end
		local name = sender:get_player_name()
		local meta = minetest.get_meta(pos)
		if name ~= meta:get_string("owner") then
			minetest.chat_send_player(name, "You don't own this LuaBlock.")
			return
		end
		if not minetest.check_player_privs(name, {server = true}) then
			minetest.chat_send_player(name, "You can't use a LuaBlock without the server privilege.")
			return
		end

		meta:set_string("code", fields.code)
		set_data(pos, fields.code, name)
		make_formspec(meta, pos)
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		return meta:get_string("owner") == player:get_player_name()
	end,
	on_destruct = function(pos)
		moremesecons.remove_data_from_pos(pos_data, pos)
	end,
	mesecons = {effector = {
		action_on = function(npos, node)
			local meta = minetest.get_meta(npos)
			local code = meta:get_string("code")
			local owner = meta:get_string("owner")
			if code == "" then
				return
			end
			if not check_data(npos, code, owner) then
				minetest.log("warning", "[moremesecons_luablock] Metadata of LuaBlock at pos "..minetest.pos_to_string(npos).." does not match its mod storage data!")
				return
			end

			local env = {}
			for k, v in pairs(_G) do
				env[k] = v
			end
			env.pos = table.copy(npos)
			env.mem = minetest.deserialize(meta:get_string("mem")) or {}

			local func, err_syntax
			if _VERSION == "Lua 5.1" then
				func, err_syntax = loadstring(code)
				if func then
					setfenv(func, env)
				end
			else
				func, err_syntax = load(code, nil, "t", env)
			end
			if not func then
				meta:set_string("errmsg", err_syntax)
				make_formspec(meta, npos)
				return
			end

			local good, err_runtime = pcall(func)

			if not good then
				meta:set_string("errmsg", err_runtime)
				make_formspec(meta, npos)
				return
			end

			meta:set_string("mem", minetest.serialize(env.mem))

			meta:set_string("errmsg", "")
			make_formspec(meta, npos)
		end
	}}
})
