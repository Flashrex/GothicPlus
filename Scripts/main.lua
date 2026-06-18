local Config = require("config")
local PlayerModule = require("modules.player")
local Regen = require("modules.regen")

local RegenEnabled = Config.health_regen_enabled or Config.mana_regen_enabled

-- Hooks
---@param self RemoteUnrealParam<APlayerController>
---@param NewPawn RemoteUnrealParam<APawn>
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)
    PlayerModule.OnClientRestart(NewPawn:get())
end)

-- Keybinds
RegisterKeyBind(Key.H, function()
    print("[GothicPlus] Hello from Gothic Remake!")
end)

-- Loops
if RegenEnabled then
    LoopAsync(Regen.IntervalMs, function()
        ExecuteInGameThread(Regen.Tick)
        return false
    end)
end

print("[GothicPlus] Mod loaded!")
