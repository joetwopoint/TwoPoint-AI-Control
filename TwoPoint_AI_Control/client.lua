-------------------------------------------------------------


-----------------------------------------------------------------------
-- TwoPoint AI Control - LEO permission sync
-----------------------------------------------------------------------

TwoPoint_AI_IsLEO = false

function TwoPoint_IsPlayerLEO()
    return TwoPoint_AI_IsLEO == true
end

RegisterNetEvent('TwoPoint_AI:SetLEOStatus')
AddEventHandler('TwoPoint_AI:SetLEOStatus', function(isLeo)
    TwoPoint_AI_IsLEO = isLeo and true or false
end)

CreateThread(function()
    -- Ask server once on join; server will respond with current group.LEO ace status
    TriggerServerEvent('TwoPoint_AI:RequestLEOStatus')
end)

-- TwoPoint AI Control - Client
-- Unified AI relationships, density, dispatch & cleanup
-------------------------------------------------------------

-- Configure in config.lua only.

-- NOTE: this build disables custom AI handling overrides and the emergency blocker logic for more stable traffic on recent FiveM artifacts.

-- =============================
-- AI RELATIONSHIPS / DENSITY / DISPATCH
-- =============================

-- Relationship setup (run once on start)
CreateThread(function()
    -- keep player neutral to self
    SetRelationshipBetweenGroups(2, `PLAYER`, `PLAYER`)

    -- civilians neutral to each other
    SetRelationshipBetweenGroups(1, `CIVMALE`, `CIVMALE`)
    SetRelationshipBetweenGroups(1, `CIVMALE`, `CIVFEMALE`)
    SetRelationshipBetweenGroups(1, `CIVFEMALE`, `CIVFEMALE`)
    SetRelationshipBetweenGroups(1, `CIVFEMALE`, `CIVMALE`)

    -- service groups
    SetRelationshipBetweenGroups(1, `COP`, `MEDIC`)
    SetRelationshipBetweenGroups(1, `MEDIC`, `COP`)
    SetRelationshipBetweenGroups(1, `FIREMAN`, `COP`)
    SetRelationshipBetweenGroups(1, `COP`, `FIREMAN`)
end)

-- Main density loop — must run every frame for *_ThisFrame natives
CreateThread(function()
    while true do
        Wait(0)
        local v = Config.VehDensity or 0.8
        local p = Config.PedDensity or 0.8
        local r = Config.RanVehDensity or 0.8
        local pa = Config.ParkCarDensity or 0.8
        local sp = Config.ScenePedDensity or 0.4

        -- per-frame multipliers
        SetVehicleDensityMultiplierThisFrame(v)
        SetPedDensityMultiplierThisFrame(p)
        SetRandomVehicleDensityMultiplierThisFrame(r)
        SetParkedVehicleDensityMultiplierThisFrame(pa)
        SetScenarioPedDensityMultiplierThisFrame(sp, sp)
        SetSomeVehicleDensityMultiplierThisFrame(v)
    end
end)

-- Dispatch / wanted — does not need to run every frame
CreateThread(function()
    if not Config.DispatchDead then return end
    -- disable all dispatch services once, then occasionally reinforce
    for i = 1, 15 do
        EnableDispatchService(i, false)
    end
    SetMaxWantedLevel(0)
    ClearPlayerWantedLevel(PlayerId())

    while true do
        Wait(5000)
        for i = 1, 15 do
            EnableDispatchService(i, false)
        end
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        SetPlayerWantedLevelNoDrop(PlayerId(), 0, false)
    end
end)

-- =============================
-- EMERGENCY CLEANUP (VEHICLES & PEDS)
-- =============================

Citizen.CreateThread(function()
    local vehicleModels = {
        "ambulance", "firetruk", "polmav", "police", "police2", "police3", "police4", "fbi", "fbi2", "policet", "policeb", "riot", "apc", "barracks", "barracks2", "barracks3", "rhino", "hydra", "lazer", "valkyrie", 
        "valkyrie2", "savage", "trailersmall2", "barrage", "chernobog", "khanjali", "menacer", "scarab", "scarab2", "scarab3", "armytanker", "avenger", "avenger2", "tula", "bombushka", "molotok", "volatol", "starling", 
        "mogul", "nokota", "strikeforce", "rogue", "cargoplane", "jet", "buzzard", "besra", "titan", "cargobob", "cargobob2", "cargobob3", "cargobob4", "akula", "hunt", "monster3", "monster4", "monster5", "bruiser",
		"bruiser2", "bruiser3", "brutus", "brutus2", "brutus3, stretch"
    }

    local pedModels = {
        "s_m_m_paramedic_01", "s_m_m_paramedic_02", "s_m_y_fireman_01", "s_m_y_pilot_01", "s_m_y_cop_01", "s_m_y_cop_02", "s_m_y_swat_01", "s_m_y_hwaycop_01", "s_m_y_marine_01", "s_m_y_marine_02", "s_m_y_marine_03",
        "s_m_m_marine_01", "s_m_m_marine_02"
    }

    if type(vehicleModels) == "table" then
        for _, modelName in ipairs(vehicleModels) do
            SetVehicleModelIsSuppressed(GetHashKey(modelName), true)
        end
    end

    if type(pedModels) == "table" then
        for _, modelName in ipairs(pedModels) do
            SetPedModelIsSuppressed(GetHashKey(modelName), true)
        end
    end

    while true do
        Citizen.Wait(5000)

        local playerPed = PlayerPedId()
        local playerLocalisation = GetEntityCoords(playerPed)
        ClearAreaOfCops(playerLocalisation.x, playerLocalisation.y, playerLocalisation.z, 400.0)

        local vehicles = GetGamePool("CVehicle") or {}
        for i = 1, #vehicles do
            local vehicle = vehicles[i]
            local model = GetEntityModel(vehicle)

            if type(vehicleModels) == "table" then
                for _, modelName in ipairs(vehicleModels) do
                    if model == GetHashKey(modelName) then
                        SetEntityAsMissionEntity(vehicle, true, true)
                        DeleteVehicle(vehicle)
                        break
                    end
                end
            end
        end

        local peds = GetGamePool("CPed") or {}
        for i = 1, #peds do
            local ped = peds[i]
            local model = GetEntityModel(ped)

            if type(pedModels) == "table" then
                for _, modelName in ipairs(pedModels) do
                    if model == GetHashKey(modelName) then
                        SetEntityAsMissionEntity(ped, true, true)
                        DeletePed(ped)
                        break
                    end
                end
            end
        end
    end
end)
-------------------------------------------------------------

-- Emergency vehicle blocker logic removed for stability on newer FiveM builds.
