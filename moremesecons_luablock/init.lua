local md5 = dofile(minetest.get_modpath(minetest.get_current_modname()).."/md5_lua/md5.lua")
local storage = minetest.get_mod_storage()
local hash_table = minetest.deserialize(storage:get_string("hash_table")) or {}

local function set_md5(pos, code)
	vector.set_data_to_pos(hash_table, pos.z,pos.y,pos.x, md5.sum(code))
	storage:set_string("hash_table", minetest.serialize(hash_table))
end

local function check_md5(pos, code)
	local stored_sum = vector.get_data_from_pos(hash_table, pos.z,pos.y,pos.x)
	if not stored_sum then
		-- Legacy
		set_md5(pos, code)
		return true
	end
	if md5.sum(code) ~= stored_sum then
		return false
	end
	return true
end


local function make_formspec(meta, pos)
	local code = meta:get_string("code")
	local errmsg = minetest.formspec_escape(meta:get_string("errmsg"))
	meta:set_string("formspec",
		"size[10,8;]" ..
		"textarea[0.5,0.5;10,7;code;Code;"..code.."]" ..
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
		set_md5(pos, fields.code)
		make_formspec(meta, pos)
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		return meta:get_string("owner") == player:get_player_name()
	end,
	mesecons = {effector = {
		action_on = function(npos, node)
			local meta = minetest.get_meta(npos)
			local code = meta:get_string("code")
			if code == "" then
				return
			end
			if not check_md5(npos, code) then
				minetest.log("warning", "[moremesecons_luablock] Code of LuaBlock at pos "..minetest.pos_to_string(npos).." does not match with its md5 checksum!")
				return
			end
			-- We do absolutely no check there.
			-- There is no limitation in the number of instruction the LuaBlock can execute
			-- or the usage it can make of loops.
			-- It is executed in the global namespace.
			-- Remember: *The LuaBlock is highly dangerous and should be manipulated cautiously!*
			local func, err = loadstring(code)
			if not func then
				meta:set_string("errmsg", err)
				make_formspec(meta, pos)
				return
			end
			-- Set the "pos" global
			local old_pos = pos -- In case there's already an existing "pos" global
			pos = table.copy(npos)
			local good, err = pcall(func)
			pos = old_pos

			if not good then -- Runtime error
				meta:set_string("errmsg", err)
				make_formspec(meta, pos)
				return
			end

			meta:set_string("errmsg", "")
			make_formspec(meta, pos)
		end
	}}
})
