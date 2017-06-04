moremesecons = {}

function moremesecons.setting(modname, settingname, default, min)
	local setting = "moremesecons_" .. modname .. "." .. settingname

	if type(default) == "boolean" then
		local ret = minetest.settings:get_bool(setting)
		if ret == nil then
			ret = default
		end
		return ret
	elseif type(default) == "string" then
		return minetest.settings:get(setting) or default
	elseif type(default) == "number" then
		local ret = tonumber(minetest.settings:get(setting)) or default
		if not ret then
			minetest.log("warning", "[moremesecons_"..modname.."]: setting '"..setting.."' must be a number. Set to default value ("..tostring(default)..").")
			ret = default
		elseif ret ~= ret then -- NaN
			minetest.log("warning", "[moremesecons_"..modname.."]: setting '"..setting.."' is NaN. Set to default value ("..tostring(default)..").")
			ret = default
		end
		if min and ret < min then
			minetest.log("warning", "[moremesecons_"..modname.."]: setting '"..setting.."' is under minimum value "..tostring(min)..". Set to minimum value ("..tostring(min)..").")
			ret = min
		end
		return ret
	end
end

-- Vector helpers
-- All the following functions are from the vector_extras mod (https://github.com/HybridDog/vector_extras).
-- If you enable that mod, its functions will be used instead of the ones defined below

if not vector.get_data_from_pos then
	function vector.get_data_from_pos(tab, z,y,x)
		local data = tab[z]
		if data then
			data = data[y]
			if data then
				return data[x]
			end
		end
	end
end

if not vector.set_data_to_pos then
	function vector.set_data_to_pos(tab, z,y,x, data)
		if tab[z] then
			if tab[z][y] then
				tab[z][y][x] = data
				return
			end
			tab[z][y] = {[x] = data}
			return
		end
		tab[z] = {[y] = {[x] = data}}
	end
end

if not vector.remove_data_from_pos then
	function vector.remove_data_from_pos(tab, z,y,x)
		if vector.get_data_from_pos(tab, z,y,x) == nil then
			return
		end
		tab[z][y][x] = nil
		if not next(tab[z][y]) then
			tab[z][y] = nil
		end
		if not next(tab[z]) then
			tab[z] = nil
		end
	end
end

if not vector.unpack then
	function vector.unpack(pos)
		return pos.z, pos.y, pos.x
	end
end
