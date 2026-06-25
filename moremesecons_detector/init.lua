-- moremesecons_detector mod by h3ndrik
-- based on the code from mesecons_detector 

local S = minetest.get_translator(minetest.get_current_modname())

dofile(minetest.get_modpath(minetest.get_current_modname()).."/inventory_scanner.lua")

if minetest.get_modpath("awards") then
	dofile(minetest.get_modpath(minetest.get_current_modname()).."/awards_detector.lua")
end

if minetest.get_modpath("playerfactions") then
	dofile(minetest.get_modpath(minetest.get_current_modname()).."/playerfactions_detector.lua")
end
