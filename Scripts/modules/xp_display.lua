local UEHelpers = require("UEHelpers")
local PlayerModule = require("modules.player")

local XPDisplay = {}

local PollIntervalMs = 250

local LevelProgressionAttributeSetClass = StaticFindObject(nil, nil, "/Script/G1R.AttributeSet_LevelProgression")

local CachedWorldDefinition = nil

local function FormatWithThousandsSeparator(Number)
    local Reversed = tostring(math.floor(Number)):reverse():gsub("(%d%d%d)", "%1.")
    return (Reversed:reverse():gsub("^%.", ""))
end

local function FindAttributeSet(ASC, AttributeSetClass)
    for _, Set in ipairs(ASC.SpawnedAttributes) do
        if Set:IsValid() and Set:IsA(AttributeSetClass) then
            return Set
        end
    end
    return nil
end

local function GetWorldDefinition()
    if CachedWorldDefinition and CachedWorldDefinition:IsValid() then
        return CachedWorldDefinition
    end

    local World = UEHelpers.GetWorld()
    local GameState = UEHelpers.GetGameStateBase()
    if not World or not World:IsValid() or not GameState or not GameState:IsValid() then
        return nil
    end

    local WorldDefinition = GameState:GetWorldDefinition(World)
    if not WorldDefinition or not WorldDefinition:IsValid() then
        return nil
    end

    CachedWorldDefinition = WorldDefinition
    return CachedWorldDefinition
end

local function ApplyFullXPText(Widget, CurrentXP, NextLevelXP)
    if not Widget:IsValid() then
        return
    end

    local Entry = Widget.StatEntry_Experience
    if not Entry or not Entry:IsValid() then
        return
    end

    Entry.TextBlock_StatValue:SetText(FText(FormatWithThousandsSeparator(CurrentXP)))
    Entry.TextBlock_StatMaxValue:SetText(FText(FormatWithThousandsSeparator(NextLevelXP)))
end

local function Poll()
    pcall(function()
        local Widgets = FindAllOf("W_CharacterStat_XP_C")
        if not Widgets or #Widgets == 0 then
            return
        end

        local _, ASC = PlayerModule.EnsureAcquired()
        local LevelSet = ASC and FindAttributeSet(ASC, LevelProgressionAttributeSetClass)
        local WorldDefinition = GetWorldDefinition()
        if not LevelSet or not WorldDefinition then
            return
        end

        local CurrentXP = math.floor(LevelSet.Experience.CurrentValue)
        local CurrentLevel = WorldDefinition:LevelFromExperience(CurrentXP)
        local NextLevelXP = WorldDefinition:ExperienceRequiredForLevel(CurrentLevel + 1)

        for _, Widget in ipairs(Widgets) do
            ApplyFullXPText(Widget, CurrentXP, NextLevelXP)
        end
    end)

    ExecuteInGameThreadWithDelay(PollIntervalMs, Poll)
end

function XPDisplay.Start()
    ExecuteInGameThreadWithDelay(PollIntervalMs, Poll)
end

return XPDisplay
