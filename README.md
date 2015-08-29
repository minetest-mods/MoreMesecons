# MoreMesecons

Based on Mesecons by Jeija

MoreMesecons is a mod for minetest wich add some mesecons items.

### New items

* `Adjustable Blinky plant` : Like a mesecons blinky plant, but... adjustable. Right-click to change the interval.
* `Craftable Command Block` : A command block with just some commands accepted. The admin can change the accepted command (first line of the init.lua), default "say" and "tell".
* `Player Killer` : This block kills the nearest player (with a maximal distance of 8 blocks by default) (if this player isn't its owner) when it receives a mesecons signal.
* `Signal Changer` : If it receives a signal on its pin "F", it turns on. If ti receives a signal on its pin "O", it turns off.
* `Switch Torch` : It connects just like Mesecons Torch. If it receives a signal, it turns on, and if it receives a second signal, it turns off.
* `Teleporter` : Both parties teleporters must be on the same axis.
* `Temporary Gate` : If it receives a mesecons signal, whatever its duration, a mesecons signal is send with a fixed duration. You can change it by right-click (in seconds) (you can write for example 0.2 to send a pulse, or 20 to send long signals).
* `Wireless` : Put 2 (or more) wireless somewhere. Change their channel by right-click. If you send a signal to a wireless, every wireless wich have the same channel will send the signal.
