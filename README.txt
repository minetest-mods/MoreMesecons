MOREMESECONS
By palige
Based on Mesecons by Jeija
With the participation of Mg

MoreMesecons add few mesecons objects to simplify circuits and add new possibilities.

NEW NODES ARE :
	SWITCH TORCH : This torch must be connected like a mesetorch. On the first mesecons signal, it switch on. On the second mesecons signal, it switch off. This is a switch controlled by a mesecons signal. You can use it like a memory for example.
	TEMPORARY GATE : This node must be connected like a mesecons delayer. If it receive a signal (short or long), it send a signal of duration can be modified by punch (1, 2, 3 or 4 seconds).
	ADJUSTABLE BLINKY PLANT : Like a blinky plant, but you can change the signal duration with a right click.
	PLAYER KILLER : This node must be connected like a player detector. If it receive a mesecons signal, the nearest player of player killer died. The maximal distance is 8.
	TELEPORTER : This node teleports the nearest player at the position of the other teleporter in the same line (two identical directions (x, z or y). For example, first teleporter is at 33,10,-1057 ; and the second can be at 33,56,-1057 but NOT in 30,56,-1057.). They must are 2 teleporters.
	WIRELESS : If you want to send a mesecons signal on very long distance, when you can't use "Mesecons", you can use "wireless" ! Put 2 wireless (or more if you want), type the channel and send a signal to the first : the second re-send it !
	CRAFTABLE COMMAND BLOCK : You can't use command block in survival... So, MoreMesecons introduce the Craftable Command Block. You can choose authorized commands : just set the "accepted_commands" list on the begin of the init.lua file. If you don't give any commands, all commands will be accepted. This is especially useful for servers administrators.