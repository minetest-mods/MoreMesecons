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

-- Storage helpers

function moremesecons.get_storage_data(storage, name)
	return {
		tab = minetest.deserialize(storage:get_string(name)) or {},
		name = name,
		storage = storage
	}
end

function moremesecons.set_data_to_pos(sto, pos, data)
	sto.tab[minetest.hash_node_position(pos)] = data
	sto.storage:set_string(sto.name, minetest.serialize(sto.tab))
end

function moremesecons.get_data_from_pos(sto, pos)
	return sto.tab[minetest.hash_node_position(pos)]
end

function moremesecons.remove_data_from_pos(sto, pos)
	sto.tab[minetest.hash_node_position(pos)] = nil
	sto.storage:set_string(sto.name, minetest.serialize(sto.tab))
end

-- Some additional vector helpers

-- The same as minetest.hash_node_position; I copied it to ensure backwards
-- compatibility and used hexadecimal number notation
local function node_position_key(pos)
	return (pos.z + 0x8000) * 0x10000 * 0x10000
		 + (pos.y + 0x8000) * 0x10000
		 +  pos.x + 0x8000
end

local MapDataStorage = {}
setmetatable(MapDataStorage, {__call = function()
	local obj = {}
	setmetatable(obj, MapDataStorage)
	return obj
end})
MapDataStorage.__index = {
	getAt = function(self, pos)
		return self[node_position_key(pos)]
	end,
	setAt = function(self, pos, data)
		-- If x, y or z is omitted, the key corresponds to a position outside
		-- of the map (hopefully), so it can be used to skip lines and planes
		local vi_z = (pos.z + 0x8000) * 0x10000 * 0x10000
		local vi_zy = vi_z + (pos.y + 0x8000) * 0x10000
		local vi = vi_zy + pos.x + 0x8000
		local is_new = self[vi] == nil
		self[vi] = data
		if is_new then
			self[vi_z] = (self[vi_z] or 0) + 1
			self[vi_zy] = (self[vi_zy] or 0) + 1
		end
	end,
	setAtI = function(self, vi, data)
		local vi_zy = vi - vi % 0x10000
		local vi_z = vi - vi % (0x10000 * 0x10000)
		local is_new = self[vi] == nil
		self[vi] = data
		if is_new then
			self[vi_z] = (self[vi_z] or 0) + 1
			self[vi_zy] = (self[vi_zy] or 0) + 1
		end
	end,
	removeAt = function(self, pos)
		local vi_z = (pos.z + 0x8000) * 0x10000 * 0x10000
		local vi_zy = vi_z + (pos.y + 0x8000) * 0x10000
		local vi = vi_zy + pos.x + 0x8000
		if self[vi] == nil then
			-- Nothing to remove
			return
		end
		self[vi] = nil
		-- Update existence information for the xy plane and x line
		self[vi_z] = self[vi_z] - 1
		if self[vi_z] == 0 then
			self[vi_z] = nil
			self[vi_zy] = nil
			return
		end
		self[vi_zy] = self[vi_zy] - 1
		if self[vi_zy] == 0 then
			self[vi_zy] = nil
		end
	end,
	iter = function(self, pos1, pos2)
		local ystride = 0x10000
		local zstride = 0x10000 * 0x10000

		-- Skip z values where no data can be found
		pos1 = vector.new(pos1)
		local vi_z = (pos1.z + 0x8000) * 0x10000 * 0x10000
		while not self[vi_z] do
			pos1.z = pos1.z + 1
			vi_z = vi_z + zstride
			if pos1.z > pos2.z then
				-- There are no values to iterate through
				return function() return end
			end
		end
		-- Skipping y values is not yet implemented and may require much code

		local xrange = pos2.x - pos1.x + 1
		local yrange = pos2.y - pos1.y + 1
		local zrange = pos2.z - pos1.z + 1

		-- x-only and y-only parts of the vector index of pos1
		local vi_y = (pos1.y + 0x8000) * 0x10000
		local vi_x =  pos1.x + 0x8000

		local y = 0
		local z = 0

		local vi = node_position_key(pos1)
		local pos = vector.new(pos1)
		local nextaction = vi + xrange
		pos.x = pos.x - 1
		vi = vi - 1
		local function iterfunc()
			-- continue along x until it needs to jump
			vi = vi + 1
			pos.x = pos.x + 1
			if vi ~= nextaction then
				local v = self[vi]
				if v == nil then
					-- No data here
					return iterfunc()
				end
				-- The returned position must not be changed
				return pos, v
			end

			-- Reset x position
			vi = vi - xrange
			-- Go along y until pos2.y is exceeded
			while true do
				y = y + 1
				pos.y = pos.y + 1
				-- Set vi to index(pos1.x, pos1.y + y, pos1.z + z)
				vi = vi + ystride
				if y == yrange then
					break
				end
				if self[vi - vi_x] then
					nextaction = vi + xrange

					vi = vi - 1
					pos.x = pos1.x - 1
					return iterfunc()
				end
				-- Nothing along this x line, so increase y again
			end

			-- Go back along y
			vi = vi - yrange * ystride
			y = 0
			pos.y = pos1.y
			-- Go along z until pos2.z is exceeded
			while true do
				z = z + 1
				pos.z = pos.z + 1
				vi = vi + zstride
				if z == zrange then
					-- Cuboid finished, return nil
					return
				end
				if self[vi - vi_x - vi_y] then
					y = 0
					nextaction = vi + xrange

					vi = vi - 1
					pos.x = pos1.x - 1
					return iterfunc()
				end
				-- Nothing in this xy plane, so increase z again
			end
		end
		return iterfunc
	end,
	iterAll = function(self)
		local previous_vi = nil
		local function iterfunc()
			local vi, v = next(self, previous_vi)
			previous_vi = vi
			if not vi then
				return
			end
			local z = math.floor(vi / (0x10000 * 0x10000))
			vi = vi - z * 0x10000 * 0x10000
			local y = math.floor(vi / 0x10000)
			if y == 0 or z == 0 then
				-- The index does not refer to a position inside the map
				return iterfunc()
			end
			local x = vi - y * 0x10000 - 0x8000
			y = y - 0x8000
			z = z - 0x8000
			return {x=x, y=y, z=z}, v
		end
		return iterfunc
	end,
	serialize = function(self)
		local indices = {}
		local values = {}
		local i = 1
		for pos, v in self:iterAll() do
			local vi = node_position_key(pos)
			-- Convert the double reversible to a string;
			-- minetest.serialize does not (yet) do this
			indices[i] = ("%.17g"):format(vi)
			values[i] = v
		end
		return minetest.serialize({
			version = "MapDataStorage_v1",
			indices = "return {" .. table.concat(indices, ",") .. "}",
			values = minetest.serialize(values),
		})
	end,
}
MapDataStorage.deserialize = function(txtdata)
	local data = minetest.deserialize(txtdata)
	if data.version ~= "MapDataStorage_v1" then
		minetest.log("error", "Unknown MapDataStorage version: " ..
			data.version)
	end
	-- I assume that minetest.deserialize correctly deserializes the indices,
	-- which are in the %a format
	local indices = minetest.deserialize(data.indices)
	local values = minetest.deserialize(data.values)
	if not indices or not values then
		return MapDataStorage()
	end
	data = MapDataStorage()
	for i = 1,#indices do
		local vi = indices[i]
		local v = values[i]
		data:setAtI(vi, v)
	end
	return data
end
moremesecons.MapDataStorage = MapDataStorage


-- Legacy

-- vector_extras there: https://github.com/HybridDog/vector_extras
-- Creates a MapDataStorage object from old vector_extras generated table
function moremesecons.load_old_data_from_pos(t)
	local data = MapDataStorage()
	for z, yxv in pairs(t) do
		for y, xv in pairs(yxv) do
			for x, v in pairs(xv) do
				data:setAt({x=x, y=y, z=z}, v)
			end
		end
	end
	return data
end

function moremesecons.load_old_dfp_storage(modstorage, name)
	local data = minetest.deserialize(modstorage:get_string(name))
	if not data then
		return
	end
	return moremesecons.load_old_data_from_pos(data)
end

function moremesecons.load_MapDataStorage_legacy(modstorage, name, oldname)
	local t_old = moremesecons.load_old_dfp_storage(modstorage, oldname)
	local t
	if t_old and t_old ~= "" then
		t = t_old
		modstorage:set_string(name, t:serialize())
		modstorage:set_string(oldname, nil)
		return t
	end
	t = modstorage:get_string(name)
	if t and t ~= "" then
		return MapDataStorage.deserialize(t)
	end
	return MapDataStorage()
end



--[[
-- This testing code shows an example usage of the MapDataStorage code
local function do_test()
	print("Test if iter returns correct positions when a lot is set")
	local data = MapDataStorage()
	local k = 0
	for x = -5, 3 do
		for y = -5, 3 do
			for z = -5, 3 do
				k = k + 1
				data:setAt({x=x, y=y, z=z}, k)
			end
		end
	end
	local expected_positions = {}
	for z = -4, 2 do
		for y = -4, 2 do
			for x = -4, 2 do
				expected_positions[#expected_positions+1] = {x=x, y=y, z=z}
			end
		end
	end
	local i = 0
	for pos in data:iter({x=-4, y=-4, z=-4}, {x=2, y=2, z=2}) do
		i = i + 1
		assert(vector.equals(pos, expected_positions[i]))
	end

	print("Test if iter works correctly on a corner")
	local found = false
	for pos in data:iter({x=-8, y=-7, z=-80}, {x=-5, y=-5, z=-5}) do
		assert(not found)
		found = true
		assert(vector.equals(pos, {x=-5, y=-5, z=-5}))
	end
	assert(found)

	print("Test if iter finds all corners")
	local expected_positions = {}
	local k = 1
	for _, z in ipairs({-9, -6}) do
		for _, y in ipairs({-9, -6}) do
			for _, x in ipairs({-8, -6}) do
				local pos = {x=x, y=y, z=z}
				expected_positions[#expected_positions+1] = pos
				data:setAt(pos, k)
				k = k + 1
			end
		end
	end
	local i = 1
	for pos, v in data:iter({x=-8, y=-9, z=-9}, {x=-6, y=-6, z=-6}) do
		assert(v == i)
		assert(vector.equals(pos, expected_positions[i]))
		i = i + 1
		--~ print("found " .. minetest.pos_to_string(pos))
	end
	assert(i == 8 + 1, "Not enough or too many corners found")

	--~ data:iterAll()
end
do_test()
--]]
