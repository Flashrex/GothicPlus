local Config = require("config")
local PlayerModule = require("modules.player")
local Regen = require("modules.regen")
local Sleep = require("modules.sleep")
local Locations = require("modules.locations")

local RegenEnabled = Config.health_regen_enabled or Config.mana_regen_enabled

-- Hooks
---@param self RemoteUnrealParam<APlayerController>
---@param NewPawn RemoteUnrealParam<APawn>
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)
    PlayerModule.OnClientRestart(NewPawn:get())
end)

-- This hook callback runs BEFORE the native function body (which applies the
-- recover-by-sleeping effect and decrements the SleepTime budget), confirmed by
-- logged attribute values being unchanged at this point. Deferring our reset by
-- a short delay lets that synchronous native work finish first, in the same
-- frame, before we write SleepTime back to full.
-- (OnEndAbility_Scriptable was tried first but never fires: it's an AngelScript-
-- bound "_Scriptable" override point, called via AS's own binding table, so
-- RegisterHook silently never triggers for it -- see LuaModdingSurface.md.)
RegisterHook("/Script/G1R.GameplayAbilitySleep:Server_ApplySleepingGameplayEffects", function(self)
    ExecuteInGameThreadWithDelay(200, Sleep.RemoveRecentlySleptPenalty)
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

if Config.map_location_labels_enabled then
    LoopAsync(Locations.PollIntervalMs, function()
        ExecuteInGameThread(Locations.Tick)
        return false
    end)
end

print("[GothicPlus] Mod loaded!")
