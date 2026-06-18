local UEHelpers = require("UEHelpers")

local PlayerModule = {}

local PollIntervalMs = 1000

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

local function NeedsAcquisition()
    return not CachedPlayer or not CachedPlayer:IsValid()
end

-- The game's UE4SS object-lookup tables are sporadically broken for this game
-- (RE-UE4SS issue #1278), so a lookup attempt can fail at any time. Retried
-- automatically by the self-scheduling poll below until one attempt succeeds.
local function TryAcquirePlayer()
    local ok, err = pcall(function()
        local Controller = UEHelpers.GetPlayerController()
        if Controller:IsValid() then
            LoadPlayer(Controller.Pawn)
        end
    end)

    if not ok then
        print("[GothicPlus] Player lookup attempt failed, retrying next tick.")
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

-- Returns the cached player pawn and AbilitySystemComponent. Either return
-- value may be nil (no player loaded yet, or the player is currently dead).
-- Acquisition itself is kept warm by the self-scheduling poll below, not
-- triggered on demand here.
function PlayerModule.EnsureAcquired()
    if not CachedPlayer or not CachedPlayer:IsValid() or CachedPlayer:IsDead() then
        return nil, nil
    end

    if not CachedASC or not CachedASC:IsValid() then
        return nil, nil
    end

    return CachedPlayer, CachedASC
end

-- Keeps the cache warm independently of any feature's config, so every
-- consumer (regen, sleep, etc.) can just call EnsureAcquired(). Reschedules
-- itself on the game thread every PollIntervalMs for as long as the mod is loaded.
local function PollPlayer()
    if NeedsAcquisition() then
        TryAcquirePlayer()
    end
    ExecuteInGameThreadWithDelay(PollIntervalMs, PollPlayer)
end

ExecuteInGameThreadWithDelay(PollIntervalMs, PollPlayer)

return PlayerModule
