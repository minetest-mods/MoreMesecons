read_globals = {
	-- Defined by Luanti
	"minetest", "vector", "PseudoRandom", "VoxelArea", "table", "ItemStack",

	-- Mods
	"digiline", "default", "creative", "mesecon"
}
files.moremesecons_utils = {globals = {"moremesecons"}}
local utils_depender = {"adjustable_blinkyplant", "adjustable_player_detector",
	"commandblock", "entity_detector", "jammer", "luablock", "playerkiller",
	"sayer", "teleporter", "timegate", "wireless"}
for _, folder_suffix in ipairs(utils_depender) do
	files["moremesecons_" .. folder_suffix] = {read_globals = {"moremesecons"}}
end
files.moremesecons_jammer.globals = {"mesecon"}

ignore = {"212", "631", "422", "432"}
