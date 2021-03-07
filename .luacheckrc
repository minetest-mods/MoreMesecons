read_globals = {
	-- Defined by Minetest
	"vector", "PseudoRandom", "VoxelArea", "table",

	-- Mods
	"digiline", "default", "creative",

	-- Required for the mesechest registration
	minetest = {
		fields = {
			register_lbm = {read_only = false},
			register_node = {read_only = false},
			registered_on_player_receive_fields = {
				read_only = false,
				other_fields = true,
			},
		},
		other_fields = true
	}
}
globals = {"moremesecons", "mesecon"}
ignore = {"212", "631", "422", "432"}
