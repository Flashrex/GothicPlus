local Config = require("config")
local PlayerModule = require("modules.player")

local Sleep = {}

local SleepAttributeSetClass = StaticFindObject(nil, nil, "/Script/G1R.AttributeSet_Sleep")

local function FindAttributeSet(ASC, AttributeSetClass)
    for _, Set in ipairs(ASC.SpawnedAttributes) do
        if Set:IsValid() and Set:IsA(AttributeSetClass) then
            return Set
        end
    end
    return nil
end

-- The game gates how much a sleep restores by a SleepTime "budget": it starts at
-- MaxSleepTime, is spent by the hours actually slept, and only refills slowly
-- over elapsed time (SleepTimeRecoveryAmount per SleepTimeRecoveryPeriod). Once
-- it hits 0, further sleeps restore nothing no matter how many hours are chosen,
-- even though RecoveryRatePerHourOfSleep (the per-hour formula) never changes.
-- Resetting the budget to full after every completed sleep removes that "slept
-- too recently" penalty while leaving the per-hour formula itself untouched.
function Sleep.RemoveRecentlySleptPenalty()
    if not Config.sleep_remove_recently_slept_penalty then
        return
    end

    pcall(function()
        local Player, ASC = PlayerModule.EnsureAcquired()
        if not Player or not ASC then
            return
        end

        local SleepSet = FindAttributeSet(ASC, SleepAttributeSetClass)
        if not SleepSet then
            return
        end

        local OldBase = SleepSet.SleepTime.BaseValue
        local OldCurrent = SleepSet.SleepTime.CurrentValue
        local Max = SleepSet.MaxSleepTime.CurrentValue

        SleepSet.SleepTime.BaseValue = Max
        SleepSet.SleepTime.CurrentValue = Max

        -- Direct struct writes bypass GAS's replication pipeline, so the UI (bound to
        -- the OnRep_* notify) never refreshes on its own. Call it manually with the
        -- pre-write value to trigger that refresh, same as a real replicated change would.
        SleepSet.OnRep_SleepTime(SleepSet, { BaseValue = OldBase, CurrentValue = OldCurrent })
    end)
end

return Sleep
