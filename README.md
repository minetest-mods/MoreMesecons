# MoreMesecons

Based on Mesecons by Jeija  
By @paly2  
With the participation of @LeMagnesium (bugfix), @Ataron (textures), and @JAPP (texture).

MoreMesecons is a mod for minetest wich add some mesecons items.

### New items

* `Adjustable Blinky plant` : Like a mesecons blinky plant, but... adjustable. Right-click to change the interval.
* `Craftable Command Block` : A command block with just some commands accepted. The admin can change the accepted command (first line of the init.lua), default "say" and "tell".
* `Dual Delayer` : If it receives a mesecons signal, port 1 turns on immediatly and port 2 turns on 0.4 seconds later. At the end of the signal, port 2 turns off immediatly and port 1 turns off 0.4 secondes later. For example, this is useful for double extenders.
* `Player Killer` : This block kills the nearest player (with a maximal distance of 8 blocks by default) (if this player isn't its owner) when it receives a mesecons signal.
* `Signal Changer` : If it receives a signal on its pin "F", it turns on. If ti receives a signal on its pin "O", it turns off.
* `Switch Torch` : It connects just like Mesecons Torch. If it receives a signal, it turns on, and if it receives a second signal, it turns off.
* `Teleporter` : Place two teleporters on the same axis. If one receives a mesecons signal, it teleports the nearest player on the second.
* `Temporary Gate` : If it receives a mesecons signal, whatever its duration, a mesecons signal is send with a fixed duration. You can change it by right-click (in seconds) (you can write for example 0.2 to send a pulse, or 20 to send long signals).
* `Wireless` : Place 2 (or more) wireless somewhere. Change their channel by right-click. If you send a signal to a wireless, every wireless wich have the same channel will send the signal.
