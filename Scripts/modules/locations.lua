local Locations = {}

Locations.PollIntervalMs = 300

local LocationUnlockQuests = {
    { Class = "Quest_Locations_AbandonedMineGlossary_AbandonedMineUnlock", Name = "Abandoned Mine", Position = { X = 870, Y = 140 } },
    { Class = "Quest_Locations_CastleRuinsGlossary_CastleRuinsUnlock", Name = "Castle Ruins", Position = { X = 810, Y = 600 } },
    { Class = "Quest_Locations_ExchangeZoneGlossary_ExchangeZoneUnlock", Name = "Exchange Zone", Position = { X = 850, Y = 80 } },
    { Class = "Quest_Locations_FreeMineGlossary_FreeMineUnlock", Name = "Free Mine", Position = { X = 390, Y = 580 } },
    { Class = "Quest_Locations_MonasteryRuinsGlossary_MonasteryRuinsUnlock", Name = "Monastery Ruins", Position = { X = 970, Y = 180 } },
    { Class = "Quest_Locations_MountainFortressGlossary_MountainFortressUnlock", Name = "Mountain Fortress", Position = { X = 710, Y = 120 } },
    { Class = "Quest_Locations_OldMineGlossary_OldMineUnlock", Name = "Old Mine", Position = { X = 550, Y = 160 } },
    { Class = "Quest_Locations_OrcEnclaveGlossary_OrcEnclaveUnlock", Name = "Orc Enclave", Position = { X = 610, Y = 700 } },
    { Class = "Quest_Locations_OrcTerritoryGlossary_OrcTerritoryUnlock", Name = "Orc Territory", Position = { X = 650, Y = 600 } },
    { Class = "Quest_Locations_StonehengeGlossary_StonehengeUnlock", Name = "Stonehenge", Position = { X = 510, Y = 520 } },
    { Class = "Quest_Locations_TrollCanyonGlossary_TrollCanyonUnlock", Name = "Troll Canyon", Position = { X = 610, Y = 100 } },
    { Class = "Quest_Locations_XardasSunkenTowerGlossary_XardasSunkenTowerUnlock", Name = "Xardas' Sunken Tower", Position = { X = 810, Y = 680 } },
    { Class = "Quest_Locations_XardasTowerGlossary_XardasTowerUnlock", Name = "Xardas' Tower", Position = { X = 950, Y = 760 } },
}

local QUEST_STATE_SUCCEEDED = 4

local TextBlockClass = StaticFindObject(nil, nil, "/Script/UMG.TextBlock")

local LabeledWidgets = {}
local WasMapOpen = false
local DiscoveredCache = {}
local DiscoveryRefreshTicks = math.ceil(10000 / Locations.PollIntervalMs)
local TicksSinceDiscoveryRefresh = DiscoveryRefreshTicks

local function LogError(Context, Err)
    print(string.format("[GothicPlus] %s failed: %s", Context, tostring(Err)))
end

local function GetVisibleMapWidgets()
    local Visible = {}
    local Ok, Instances = pcall(FindAllOf, "W_Map_C")
    if not Ok then
        LogError("FindAllOf(W_Map_C)", Instances)
        return Visible
    end

    for _, MapWidget in ipairs(Instances or {}) do
        if MapWidget:IsValid() and MapWidget:IsVisible() then
            table.insert(Visible, MapWidget)
        end
    end
    return Visible
end

local function IsLocationDiscovered(Location)
    local Ok, Instances = pcall(FindAllOf, Location.Class)
    if not Ok then
        LogError("FindAllOf(" .. Location.Class .. ")", Instances)
        return false
    end

    local Quest = Instances and Instances[1]
    return Quest ~= nil and Quest:IsValid() and Quest.State == QUEST_STATE_SUCCEEDED
end

local function RefreshDiscoveredLocations()
    local Discovered = {}
    for _, Location in ipairs(LocationUnlockQuests) do
        if IsLocationDiscovered(Location) then
            table.insert(Discovered, Location)
        end
    end
    return Discovered
end

local function ApplyLabelStyle(NewWidget, Location)
    NewWidget.Text = FText(Location.Name)
    NewWidget:SetVisibility(0)
    NewWidget:SetColorAndOpacity({ SpecifiedColor = { R = 0.91145801544189, G = 0.75894498825073, B = 0.61238598823547, A = 1 }, ColorUseRule = 0 })
    NewWidget:SetShadowOffset({ X = 1, Y = 1 })
    NewWidget:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 1 })

    local Font = NewWidget.Font
    Font.Size = 16
    Font.TypefaceFontName = FName("Default", 1)

    local Outline = Font.OutlineSettings
    Outline.OutlineSize = 2
    NewWidget:SetFont(Font)
end

local function CreateLabel(WidgetTree, Panel, Location)
    local NewWidget = StaticConstructObject(TextBlockClass, WidgetTree)
    if not NewWidget or not NewWidget:IsValid() then
        return
    end

    ApplyLabelStyle(NewWidget, Location)

    local NewSlot = Panel:AddChildToCanvas(NewWidget)
    if not NewSlot or not NewSlot:IsValid() then
        return
    end

    NewSlot:SetPosition(Location.Position)
    NewSlot:SetSize({ X = 200, Y = 50 })
end

local function GetLabeledSet(MapWidget)
    local WidgetKey = MapWidget:GetFullName()
    local Labeled = LabeledWidgets[WidgetKey]
    if not Labeled then
        Labeled = {}
        LabeledWidgets[WidgetKey] = Labeled
    end
    return Labeled
end

local function RenderLabelsOnMap(MapWidget, Discovered)
    if not MapWidget:IsValid() then
        return
    end

    local Panel = MapWidget.CanvasPanel_CustomMarkers
    local WidgetTree = MapWidget.WidgetTree
    if not Panel or not Panel:IsValid() or not WidgetTree or not WidgetTree:IsValid() then
        return
    end

    local Labeled = GetLabeledSet(MapWidget)
    for _, Location in ipairs(Discovered) do
        if not Labeled[Location.Name] then
            local Ok, Err = pcall(CreateLabel, WidgetTree, Panel, Location)
            if not Ok then
                LogError("CreateLabel(" .. Location.Name .. ")", Err)
            end
            Labeled[Location.Name] = true
        end
    end
end

local function RenderLabels(Discovered, Maps)
    if #Discovered == 0 or #Maps == 0 then
        return
    end

    if not TextBlockClass or not TextBlockClass:IsValid() then
        return
    end

    for _, MapWidget in ipairs(Maps) do
        RenderLabelsOnMap(MapWidget, Discovered)
    end
end

local function RefreshDiscoveryCacheIfDue()
    TicksSinceDiscoveryRefresh = TicksSinceDiscoveryRefresh + 1
    if TicksSinceDiscoveryRefresh < DiscoveryRefreshTicks then
        return
    end

    TicksSinceDiscoveryRefresh = 0
    DiscoveredCache = RefreshDiscoveredLocations()
end

local function HandleMapOpenTransition(VisibleMaps)
    local IsOpen = #VisibleMaps > 0
    if IsOpen and not WasMapOpen then
        DiscoveredCache = RefreshDiscoveredLocations()
        TicksSinceDiscoveryRefresh = 0
        RenderLabels(DiscoveredCache, VisibleMaps)
    end
    WasMapOpen = IsOpen
end

function Locations.Tick()
    local Ok, Err = pcall(function()
        RefreshDiscoveryCacheIfDue()
        HandleMapOpenTransition(GetVisibleMapWidgets())
    end)
    if not Ok then
        LogError("Locations.Tick", Err)
    end
end

return Locations
