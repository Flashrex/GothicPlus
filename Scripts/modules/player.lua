local UEHelpers = require("UEHelpers")

local PlayerModule = {}

local CachedPlayer = nil
local CachedASC = nil
local AcquiredAndPrinted = false

local function LoadPlayer(Player)
    if not Player or not Player:IsValid() then
        return
    end

    local ASC = Player:GetAbilitySystemComponent()
    if not ASC or not ASC:IsValid() then
        return
    end

    CachedPlayer = Player
    CachedASC = ASC
end

-- The game's UE4SS object-lookup tables are sporadically broken for this game
-- (RE-UE4SS issue #1278), so a lookup attempt can fail at any time. Retried
-- every call to EnsureAcquired() until one attempt succeeds.
local function TryAcquirePlayer()
    local ok, err = pcall(function()
        local Controller = UEHelpers.GetPlayerController()
        if Controller:IsValid() then
            LoadPlayer(Controller.Pawn)
        end
    end)

    if not ok then
        print("[GothicPlus] Player lookup attempt failed, retrying next tick: " .. tostring(err))
        return
    end

    if CachedPlayer and not AcquiredAndPrinted then
        AcquiredAndPrinted = true
        print("[GothicPlus] Player acquired.")
    end
end

-- Called from main.lua's PlayerController:ClientRestart hook.
function PlayerModule.OnClientRestart(NewPawn)
    pcall(LoadPlayer, NewPawn)
end

-- Returns the cached player pawn and AbilitySystemComponent, re-acquiring if
-- not yet cached or no longer valid. Either return value may be nil (no
-- player loaded yet, or the player is currently dead).
function PlayerModule.EnsureAcquired()
    if not CachedPlayer or not CachedPlayer:IsValid() then
        TryAcquirePlayer()
    end

    if not CachedPlayer or not CachedPlayer:IsValid() or CachedPlayer:IsDead() then
        return nil, nil
    end

    if not CachedASC or not CachedASC:IsValid() then
        return nil, nil
    end

    return CachedPlayer, CachedASC
end

return PlayerModule
