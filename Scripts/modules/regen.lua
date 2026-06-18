local Config = require("config")
local PlayerModule = require("modules.player")

local Regen = {}

Regen.IntervalMs = 1000  -- shared tick interval for both health and mana

local HealthAttributeSetClass = StaticFindObject(nil, nil, "/Script/G1R.AttributeSet_Health")
local ManaAttributeSetClass   = StaticFindObject(nil, nil, "/Script/G1R.AttributeSet_Mana")

local function RegenAttribute(AttributeSet, FieldName, MaxFieldName, Amount, RepNotifyName)
    local OldBase = AttributeSet[FieldName].BaseValue
    local OldCurrent = AttributeSet[FieldName].CurrentValue
    local Max = AttributeSet[MaxFieldName].CurrentValue
    local New = math.min(OldCurrent + Amount, Max)

    AttributeSet[FieldName].BaseValue = New
    AttributeSet[FieldName].CurrentValue = New

    -- Direct struct writes bypass GAS's replication pipeline, so the UI (bound to the
    -- OnRep_* notify) never refreshes on its own. Call it manually with the pre-write
    -- value to trigger that refresh, same as a real replicated change would.
    AttributeSet[RepNotifyName](AttributeSet, { BaseValue = OldBase, CurrentValue = OldCurrent })
end

local function FindAttributeSet(ASC, AttributeSetClass)
    for _, Set in ipairs(ASC.SpawnedAttributes) do
        if Set:IsValid() and Set:IsA(AttributeSetClass) then
            return Set
        end
    end
    return nil
end

function Regen.Tick()
    pcall(function()
        local Player, ASC = PlayerModule.EnsureAcquired()
        if not Player or not ASC then
            return
        end

        if Config.health_regen_enabled then
            local HealthSet = FindAttributeSet(ASC, HealthAttributeSetClass)
            if HealthSet then
                RegenAttribute(HealthSet, "Health", "MaxHealth", Config.health_per_tick, "OnRep_Health")
            end
        end

        if Config.mana_regen_enabled then
            local ManaSet = FindAttributeSet(ASC, ManaAttributeSetClass)
            if ManaSet then
                RegenAttribute(ManaSet, "Mana", "MaxMana", Config.mana_per_tick, "OnRep_Mana")
            end
        end
    end)
end

return Regen
