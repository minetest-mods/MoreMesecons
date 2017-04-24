# MoreMesecons

Based on Mesecons by Jeija  
By @paly2 and @HybridDog  
With the participation of @LeMagnesium (bugfix), @Ataron (textures), @JAPP (texture).  

Dependencies: [Mesecons](https://github.com/Jeija/minetest-mod-mesecons/)  
Optional dependencies: [vector_extras](https://github.com/HybridDog/vector_extras/) [digilines](https://github.com/minetest-mods/digilines)

MoreMesecons is a mod for minetest which adds some mesecons items.

[Here](http://github.com/minetest-mods/MoreMesecons/wiki)'s the wiki !

## New items

* `Adjustable Blinky plant` : Like a mesecons blinky plant, but... adjustable. Right-click to change the interval.
* `Adjustable Player Detector` : Like a mesecons player detector, but you can change its detection radius by right-click.
* `Craftable Command Block` : A command block with just some commands accepted. The admin can change the accepted command (first line of the init.lua), default "tell". Only "@nearest" can be used in the commands, and the admin can change the maximum distance of "@nearest" (default 8 blocks).
* `Conductor Signal Changer` : Like a diode which can be activated by sending a signal on its pin "F", and deactivated by sending a signal on its pin "O".
* `Dual Delayer` : If it receives a mesecons signal, port 1 turns on immediatly and port 2 turns on 0.4 seconds later. At the end of the signal, port 2 turns off immediatly and port 1 turns off 0.4 secondes later. For example, this is useful for double extenders.
* `Entity Detector` : You can use it to detect an entity. You can choose the entity to detect by right-click (use itemstring, for example "mobs:rat". To detect a dropped item, write "__builtin:item". To detect a specific dropped item, write its itemstring (for example "default:cobble")).
* `Igniter` : This node is a lighter that ignites its adjacent flammable nodes (including TNT).
* `Injector Controller` : This node is useful to activate/deactivate a pipeworks filter injector : it sends a blinky signal.
* `Jammer` : If turned on, this node stops mesecons in a radius of 10 nodes.
* `LuaBlock`: This block allows its owner to execute any Lua code in the global environment when turned on. Using it requires the server privilege.
* `Luacontroller Template Tool` : This tool is very useful to manipulate templates with luacontrollers. Just click with it on a luacontroller, then you'll see a formspec.
* `Player Killer` : This block kills the nearest player (with a maximal distance of 8 blocks by default) (if this player isn't its owner) when it receives a mesecons signal.
* `Sayer` : This node sends a message to every players inside a radius of 8 nodes.
* `Signal Changer` : If it receives a signal on its pin "F", it turns on. If it receives a signal on its pin "O", it turns off. Note : an inverted signal is sended at the other end of the arrow.
* `Switch Torch` : It connects just like Mesecons Torch. If it receives a signal, it turns on, and if it receives a second signal, it turns off.
* `Teleporter` : If you place one teleporter, it teleports the nearest player on itself when it receives a mesecons signal. If you place two teleporters on the same axis, when one receives a mesecons signal, it teleports the nearest player on the second (with a maximal distance of 50 nodes by default). The player teleporter must be inside a radius of 25 nodes.
* `Time Gate` : If it receives a mesecons signal, whatever its duration, a mesecons signal is send with a fixed duration. You can change it in the formspec by right-clicking on the gate.
* `Wireless` : Place 2 (or more) wireless somewhere. Change their channel by right-click. If you send a signal to a wireless, every wireless wich have the same channel will send the signal. Compatible with digiline mod.
* `Wireless Jammer` : If it receives a mesecons signal, it deactivates all wireless (receptors) in a radius of 15 nodes.

## Settings

You can set the settings by using the Minetest GUI ("Settings" tab -> Advanced settings -> Mods -> MoreMesecons).

## The Sayer and the Speech Dispatcher

[Speech Dispatcher project](http://freecode.com/projects/speech-dispatcher)

The Sayer item is able to speak on your speakers using the speech dispatcher, under these conditions:
1. The moremesecons_sayer mod is present in your trusted_mods setting
2. You are playing in singleplayer.
3. You are using a POSIX-compliant system and a sh-compatible shell (such as bash, dash, zsh...). Microsoft Windows is NOT POSIX-compliant.
4. The speech dispatcher is installed on your system.

The mod is able to detect issues 1, 2, and 4 by itself and then disable the speech dispatcher ; however, if you are using a non-POSIX-compliant system, the mod will crash on startup and you will need to disable the speech dispatcher manually (Settings tab -> Advanced settings -> Mods -> MoreMesecons -> Sayer -> Use the Speech Dispatcher).
