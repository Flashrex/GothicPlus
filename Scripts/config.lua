local CONFIG_FILE_PATH = "ue4ss/Mods/GothicPlus/config.ini"

local Defaults = {
    health_regen_enabled = true,
    health_percent_per_tick = 1,
    mana_regen_enabled = true,
    mana_percent_per_tick = 1,
    sleep_remove_recently_slept_penalty = true,
    map_location_labels_enabled = true,
}

local function ParseValue(RawValue)
    if RawValue == "true" then
        return true
    elseif RawValue == "false" then
        return false
    end

    local AsNumber = tonumber(RawValue)
    if AsNumber then
        return AsNumber
    end

    return RawValue
end

local function LoadConfigFile(Path)
    local Values = {}

    local File = io.open(Path, "r")
    if not File then
        print("[GothicPlus] config.ini not found, using default settings.")
        return Values
    end

    for Line in File:lines() do
        if not Line:match("^%s*#") then
            local Key, RawValue = Line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
            if Key then
                Values[Key] = ParseValue(RawValue)
            end
        end
    end

    print("[GothicPlus] Loaded config from config.ini")
    File:close()
    return Values
end

local LoadedValues = LoadConfigFile(CONFIG_FILE_PATH)

local Config = {}
for Key, DefaultValue in pairs(Defaults) do
    if LoadedValues[Key] ~= nil then
        Config[Key] = LoadedValues[Key]
    else
        Config[Key] = DefaultValue
    end
end

return Config
