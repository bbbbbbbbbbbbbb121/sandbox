# Hi, I made this sandbox script for fun because xeno pastes are shit.

**How to use**
Check the original source code, If you don't understand lua or cant be asked to read it:

Sandbox() takes 3 arguments, but you only should use 1. (First argument, which is instance)
## Normally, You sandbox EVERY instance in the game to avoid the sandbox getting bypassed, you can do that via
```lua
getgenv().game = Sandbox(game)
getgenv().Game = game
getgenv().workspace = game.Workspace
getgenv().Workspace = game.Workspace
getgenv().script = Sandbox(script)
```

Okay, Next:

HookService() - Takes 2 arguments, (Service name, Methods)
You use this to hook methods, for example:
```lua
HookService("Players", {
	"LocalPlayer.Kick", function(self, Message)
    print("LocalPlayer.Kick attempt prevented, Kick message:",Message)
  end
})
```

Breaking it down:
"Players" is the service which's methods we are hooking.
The second argument is a table with 2 values.
"LocalPlayer.Kick" is the method name, You can use . if you're trying to access an object's method like LocalPlayer that isnt directly in players.
function(self, ... is the function that gets called instead of the original, it gets called with the original function's arguments, for example:
LocalPlayer:Kick("HWID Mismatch")
Output -> LocalPlayer.Kick attempt prevented, Kick message: HWID Mismatch
self is the object itself, you dont need to pay attention to that if you're new to coding.
