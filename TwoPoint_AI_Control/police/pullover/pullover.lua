-- TwoPoint AI Control - rewritten pullover system
-- Replaces the legacy pullover flow with a simpler, stable stop system.

offense = {"WANTED BY LSPD","WANTED FOR ASSAULT","WANTED FOR UNPAID FINES","WANTED FOR RUNNING FROM THE POLICE","WANTED FOR EVADING LAW","WANTED FOR HIT AND RUN","WANTED FOR DUI"}
illegalItems = {"a knife.","a pistol.","a fake ID card.","an illegal item.","an empty bottle of beer.","bags with suspicious white powder.","an AK-47.","an armed rifle.","a rifle.","a shotgun.","an UZI.","a weapon."}

local firstNames = {"John","Mike","Sam","Arthur","Curtis","Elijah","Jeffrey","Marcus","Tony","Lewis","Edward","Jamal","Benjamin","Oscar","Victor","Owen","Alex","Gavin","Hunter","Aaron","Chad","Mario","Pablo","William","George","Jordan","Emma","Ava","Bella","Sarah","Vivian","Mia","Lily","Grace","Rachel","June","Claire","Ariana","Brooke","Sofia"}
local lastNames = {"Hansen","Malone","Barnett","Cooper","Sosa","Castaneda","Quinn","Stanton","Gonzalez","Moore","King","Rivera","Perez","Wilson","Pacheco","Bryan","Bruce","Woods","Maxwell","Roman","Douglas","Carter","Duran","Miller","Ward","Morgan","White","Burns","Daniels","Powell","Thomas","Taylor","Ramsey","Davis","Campbell","Ford","Moran","Welch","Collins","May"}

stopped = false
mimicking = false
following = false
lockedin = false
notification = false
fleeing = false

targetVeh = nil
stoppedVeh = nil
stoppedDriver = nil
targetBlip = nil

driverQuestioned = false
vehPlateNum = nil
regOwner = nil
regYear = nil
flags = "~g~NONE"
driverName = nil
fullDriverDob = nil
pedFlags = "~g~NONE"
citations = 0
breathNum = 0
cannabis = "~g~Negative"
cocaine = "~g~Negative"
speech = "Normal"
price = nil
reason = nil

local distanceToCheck = 20.0

local function tpNotify(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function ShowNotification(text)
    tpNotify(text)
end

function ShowHelp()
    SetTextComponentFormat("STRING")
    AddTextComponentString("Activate your ~r~siren~w~ to stop the vehicle!")
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
    notification = true
    Wait(5000)
    notification = false
end

function ShowMenuHelp()
    SetTextComponentFormat("STRING")
    AddTextComponentString("Press ~b~Ctrl + E~w~ to talk to the driver.")
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
    notification = true
    Wait(5000)
    notification = false
end

local function titleCase(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function randomProfile()
    local fname = firstNames[math.random(#firstNames)]
    local lname = lastNames[math.random(#lastNames)]
    driverName = fname .. " " .. lname
    local y = math.random(1965, 2003)
    local m = math.random(1, 12)
    local d = math.random(1, 28)
    fullDriverDob = m .. "/" .. d .. "/" .. y
    regOwner = driverName
    regYear = tostring(math.random(1998, 2022))
    citations = math.random(0, 6)
    breathNum = (math.random(100) > 80) and math.random(1, 14) or 0
    cannabis = (math.random(100) > 88) and "~r~Positive" or "~g~Negative"
    cocaine = (math.random(100) > 94) and "~r~Positive" or "~g~Negative"
    pedFlags = (math.random(100) > 85) and offense[math.random(#offense)] or "~g~NONE"
    flags = "~g~NONE"
    if math.random(100) > 94 then flags = "~r~STOLEN" end
    if math.random(100) > 90 then flags = "~r~UNREGISTERED" end
    if math.random(100) > 92 then flags = "~r~UNINSURED" end
end

local function clearTargetBlip()
    if targetBlip and DoesBlipExist(targetBlip) then
        RemoveBlip(targetBlip)
    end
    targetBlip = nil
end

local function setTargetBlip(veh)
    clearTargetBlip()
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        targetBlip = AddBlipForEntity(veh)
        SetBlipSprite(targetBlip, 225)
        SetBlipColour(targetBlip, 3)
        SetBlipScale(targetBlip, 0.8)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Traffic Stop")
        EndTextCommandSetBlipName(targetBlip)
    end
end

local function isOccupiedVehicle(veh)
    if veh == 0 or not DoesEntityExist(veh) then return False end
    return GetPedInVehicleSeat(veh, -1) ~= 0 or GetPedInVehicleSeat(veh, 0) ~= 0
end

local function TwoPoint_FindVehicleAhead(playerVeh, maxDist)
    if playerVeh == 0 or not DoesEntityExist(playerVeh) then return 0 end

    local pCoords = GetEntityCoords(playerVeh)
    local forward = GetEntityForwardVector(playerVeh)
    local vehicles = GetGamePool('CVehicle') or {}

    local bestVeh = 0
    local bestScore = 999999.0

    for _, veh in ipairs(vehicles) do
        if veh ~= playerVeh and DoesEntityExist(veh) and not IsEntityDead(veh) then
            local vCoords = GetEntityCoords(veh)
            local dx = vCoords.x - pCoords.x
            local dy = vCoords.y - pCoords.y
            local dz = vCoords.z - pCoords.z
            local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

            if dist <= (maxDist or 20.0) then
                local mag = dist
                if mag > 0.001 then
                    local dirX = dx / mag
                    local dirY = dy / mag
                    local dirZ = dz / mag
                    local dot = forward.x * dirX + forward.y * dirY + forward.z * dirZ
                    if dot > 0.45 then
                        local driver = GetPedInVehicleSeat(veh, -1)
                        if driver ~= 0 and not IsPedAPlayer(driver) then
                            local score = dist - (dot * 2.0)
                            if score < bestScore then
                                bestScore = score
                                bestVeh = veh
                            end
                        end
                    end
                end
            end
        end
    end

    return bestVeh
end

local function findPedAhead(maxDist)
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local peds = GetGamePool('CPed') or {}
    local bestPed = 0
    local bestScore = 999999.0

    for _, ped in ipairs(peds) do
        if ped ~= playerPed and DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsEntityDead(ped) then
            local coords = GetEntityCoords(ped)
            local dx = coords.x - pCoords.x
            local dy = coords.y - pCoords.y
            local dz = coords.z - pCoords.z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist <= (maxDist or 5.0) then
                local mag = dist
                if mag > 0.001 then
                    local dirX = dx / mag
                    local dirY = dy / mag
                    local dirZ = dz / mag
                    local dot = forward.x * dirX + forward.y * dirY + forward.z * dirZ
                    if dot > 0.25 then
                        local score = dist - dot
                        if score < bestScore then
                            bestScore = score
                            bestPed = ped
                        end
                    end
                end
            end
        end
    end

    return bestPed
end

function ALPR(vehicle)
    if vehicle == nil or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local vehicleHash = GetEntityModel(vehicle)
    local numPlate = GetVehicleNumberPlateText(vehicle)
    tpNotify("Getting vehicle information...")
    Wait(1000)
    tpNotify("~b~LSPD Database:~w~\nPlate: ~y~" .. numPlate .. "~w~\nModel: ~y~" .. GetLabelText(GetDisplayNameFromVehicleModel(vehicleHash)))
end

local function beginStop()
    stoppedVeh = targetVeh
    if stoppedVeh == nil or stoppedVeh == 0 or not DoesEntityExist(stoppedVeh) then
        tpNotify("No valid occupied vehicle found in front of you.")
        return
    end

    stoppedDriver = GetPedInVehicleSeat(stoppedVeh, -1)
    if stoppedDriver == 0 then
        tpNotify("No driver found in target vehicle.")
        return
    end

    SetEntityAsMissionEntity(stoppedVeh, true, true)
    SetEntityAsMissionEntity(stoppedDriver, true, true)
    SetDriverAbility(stoppedDriver, 1.0)
    SetDriverAggressiveness(stoppedDriver, 0.0)

    randomProfile()
    vehPlateNum = GetVehicleNumberPlateText(stoppedVeh)
    setTargetBlip(stoppedVeh)

    local vehPos = GetEntityCoords(stoppedVeh)
    local vehFwd = GetEntityForwardVector(stoppedVeh)
    local stopX = vehPos.x + (vehFwd.x * 16.0) + (vehFwd.y * 3.5)
    local stopY = vehPos.y + (vehFwd.y * 16.0) - (vehFwd.x * 3.5)
    local stopZ = vehPos.z

    TaskVehicleDriveToCoordLongrange(stoppedDriver, stoppedVeh, stopX, stopY, stopZ, 10.0, 786603, 12.0)

    ALPR(stoppedVeh)

    CreateThread(function()
        local timeout = GetGameTimer() + 15000
        while DoesEntityExist(stoppedVeh) and DoesEntityExist(stoppedDriver) and GetGameTimer() < timeout do
            Wait(250)
            local speed = GetEntitySpeed(stoppedVeh)
            local cur = GetEntityCoords(stoppedVeh)
            local dx = cur.x - stopX
            local dy = cur.y - stopY
            local dz = cur.z - stopZ
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist < 8.0 or speed < 1.5 then
                break
            end
        end

        if DoesEntityExist(stoppedVeh) and DoesEntityExist(stoppedDriver) then
            ClearPedTasks(stoppedDriver)
            TaskVehicleTempAction(stoppedDriver, stoppedVeh, 27, 2500)
            SetVehicleEngineOn(stoppedVeh, false, false, true)
            RollDownWindows(stoppedVeh)
            stopped = true
            mimicking = false
            following = false
            lockedin = false
            fleeing = false
            ShowMenuHelp()
            tpNotify("Vehicle stopped.")
        end
    end)
end

CreateThread(function()
    while true do
        if TwoPoint_IsPlayerLEO and not TwoPoint_IsPlayerLEO() then
            -- ignore
        elseif IsControlJustPressed(0, kbpomnu) or IsControlJustPressed(0, ctrpomnu) then
            local playerPed = PlayerPedId()
            local playerVeh = GetVehiclePedIsIn(playerPed, false)
            if playerVeh ~= 0 and GetVehicleClass(playerVeh) == 18 then
                targetVeh = TwoPoint_FindVehicleAhead(playerVeh, distanceToCheck)
                if stopped then
                    TriggerEvent('po:release')
                elseif mimicking then
                    TriggerEvent('po:unmimic')
                elseif following then
                    TriggerEvent('po:unfollow')
                else
                    if targetVeh == 0 or not DoesEntityExist(targetVeh) then
                        tpNotify("No valid occupied vehicle found in front of you.")
                    else
                        if IsVehicleSirenOn(playerVeh) then
                            TriggerEvent('po:pullover')
                        else
                            if lockedin then
                                TriggerEvent('po:unlock')
                            else
                                TriggerEvent('po:lock')
                            end
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if stopped and stoppedVeh and DoesEntityExist(stoppedVeh) then
            SetVehicleEngineOn(stoppedVeh, false, false, true)
        end
        if notification then
            ShowHelp()
        end
    end
end)

RegisterCommand("mimic", function() TriggerEvent('pis:mimic') end)
RegisterNetEvent('pis:mimic')
AddEventHandler('pis:mimic', function()
    if stopped then
        TriggerEvent('po:mimic')
    elseif mimicking then
        TriggerEvent('po:unmimic')
    else
        tpNotify("You need to pull over a vehicle first.")
    end
end)

RegisterNetEvent('po:mimic')
AddEventHandler('po:mimic', function()
    if not stoppedVeh or not DoesEntityExist(stoppedVeh) or not stoppedDriver or not DoesEntityExist(stoppedDriver) then
        tpNotify("No valid stopped vehicle.")
        return
    end
    stopped = false
    following = false
    mimicking = true
    tpNotify("Target vehicle is now mimicking you.")
    CreateThread(function()
        while mimicking and DoesEntityExist(stoppedVeh) and DoesEntityExist(stoppedDriver) do
            Wait(0)
            local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
            if playerVeh == 0 then break end
            local speedVect = GetEntitySpeedVector(playerVeh, true)
            if speedVect.y > 0 and reverseWithPlayer then
                SetVehicleForwardSpeed(stoppedVeh, GetEntitySpeed(playerVeh))
            elseif speedVect.y < 0 and reverseWithPlayer then
                SetVehicleForwardSpeed(stoppedVeh, -1 * GetEntitySpeed(playerVeh))
            end
            SetVehicleSteeringAngle(stoppedVeh, GetVehicleSteeringAngle(playerVeh))
            while IsEntityInAir(stoppedVeh) do Wait(0) end
        end
    end)
end)

RegisterNetEvent('po:unmimic')
AddEventHandler('po:unmimic', function()
    mimicking = false
    stopped = true
    tpNotify("Target vehicle is no longer mimicking you.")
    if DoesEntityExist(stoppedDriver) and DoesEntityExist(stoppedVeh) then
        TaskVehicleTempAction(stoppedDriver, stoppedVeh, 27, 1500)
        SetVehicleEngineOn(stoppedVeh, false, false, true)
    end
end)

RegisterCommand("follow", function() TriggerEvent('pis:follow') end)
RegisterNetEvent('pis:follow')
AddEventHandler('pis:follow', function()
    if stopped then
        TriggerEvent('po:follow')
    elseif following then
        TriggerEvent('po:unfollow')
    else
        tpNotify("You need to pull over a vehicle first.")
    end
end)

RegisterNetEvent('po:follow')
AddEventHandler('po:follow', function()
    if not stoppedVeh or not DoesEntityExist(stoppedVeh) or not stoppedDriver or not DoesEntityExist(stoppedDriver) then
        tpNotify("No valid stopped vehicle.")
        return
    end
    stopped = false
    mimicking = false
    following = true
    tpNotify("Target vehicle is now following you.")
    CreateThread(function()
        while following and DoesEntityExist(stoppedVeh) and DoesEntityExist(stoppedDriver) do
            Wait(750)
            local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
            if playerVeh ~= 0 then
                local pvPos = GetEntityCoords(playerVeh)
                TaskVehicleDriveToCoord(stoppedDriver, stoppedVeh, pvPos.x, pvPos.y, pvPos.z, 10.0, 0, GetEntityModel(stoppedVeh), 786603, 2.0, true)
            end
        end
    end)
end)

RegisterNetEvent('po:unfollow')
AddEventHandler('po:unfollow', function()
    following = false
    stopped = true
    tpNotify("Target vehicle is no longer following you.")
    if DoesEntityExist(stoppedDriver) and DoesEntityExist(stoppedVeh) then
        TaskVehicleTempAction(stoppedDriver, stoppedVeh, 27, 1500)
        SetVehicleEngineOn(stoppedVeh, false, false, true)
    end
end)

RegisterNetEvent('po:pullover')
AddEventHandler('po:pullover', function()
    beginStop()
end)

RegisterCommand("carcheck", function()
    tpNotify("Stopped: " .. tostring(stopped) .. " | DriverQuestioned: " .. tostring(driverQuestioned))
end)

RegisterCommand("runplate", function(_, args)
    local plateArg = args and args[1] or nil
    if targetVeh == nil or targetVeh == 0 or not DoesEntityExist(targetVeh) then
        tpNotify("No target vehicle.")
        return
    end
    local currentPlate = GetVehicleNumberPlateText(targetVeh)
    TriggerEvent('radio')
    tpNotify("~b~LSPD Database: ~w~\nRunning ~o~" .. tostring(plateArg or currentPlate) .. "~w~.")
    Wait(1200)
    tpNotify("~w~Reg. Owner: ~y~" .. tostring(regOwner) .. "~w~\nReg. Year: ~y~" .. tostring(regYear) .. "~w~\nFlags: ~y~" .. tostring(flags))
end)

RegisterNetEvent('pis:ticket')
AddEventHandler('pis:ticket', function()
    if not reason or not price then
        tpNotify("~r~Please select a reason and a price!")
        return
    end
    tpNotify("~o~Officer:~w~ I'm issuing you a citation of ~g~" .. tostring(price) .. " ~w~for ~y~" .. tostring(reason))
    if speech == "Aggressive" then
        tpNotify("~o~Driver:~w~ Oh come on!")
    else
        tpNotify("~o~Driver:~w~ Alright.")
    end
end)

RegisterNetEvent('pis:getplate')
AddEventHandler('pis:getplate', function()
    if targetVeh and targetVeh ~= 0 and DoesEntityExist(targetVeh) then
        vehPlateNum = GetVehicleNumberPlateText(targetVeh)
    end
end)

RegisterNetEvent('pis:runplate')
AddEventHandler('pis:runplate', function()
    TriggerEvent('radio')
    tpNotify("~b~LSPD Database: ~w~\nRunning ~o~" .. tostring(plate or vehPlateNum or "UNKNOWN") .. "~w~.")
    Wait(1200)
    tpNotify("~w~Reg. Owner: ~y~" .. tostring(regOwner) .. "~w~\nReg. Year: ~y~" .. tostring(regYear) .. "~w~\nFlags: ~y~" .. tostring(flags))
end)

RegisterNetEvent('pis:runid')
AddEventHandler('pis:runid', function()
    if not driverQuestioned then
        tpNotify("~r~You have to ask for driver's ID first!")
        return
    end
    TriggerEvent('radio')
    tpNotify("~b~LSPD Database: ~w~\nRunning ~o~" .. tostring(driverName) .. "~w~.")
    Wait(1200)
    tpNotify("~y~" .. tostring(driverName) .. "~w~ | ~b~" .. tostring(fullDriverDob) .. "\n~w~Citations: ~r~" .. tostring(citations) .. "\n~w~Flags: ~r~" .. tostring(pedFlags))
end)

RegisterNetEvent('pis:search')
AddEventHandler('pis:search', function()
    local ped = findPedAhead(4.0)
    if ped == 0 and stoppedDriver and DoesEntityExist(stoppedDriver) then ped = stoppedDriver end
    if ped ~= 0 then
        tpNotify("~b~Searching~w~ the subject...")
        Wait(2500)
        if math.random(100) > 70 then
            tpNotify("~w~Found ~r~" .. illegalItems[math.random(#illegalItems)])
        else
            tpNotify("~w~Found ~g~nothing of interest.")
        end
    elseif stoppedVeh and DoesEntityExist(stoppedVeh) then
        tpNotify("~b~Searching~w~ the vehicle...")
        Wait(3000)
        if math.random(100) > 65 then
            tpNotify("~w~Found ~r~" .. illegalItems[math.random(#illegalItems)])
        else
            tpNotify("~w~Found ~g~nothing of interest.")
        end
    else
        tpNotify("~r~You must be looking at the target!")
    end
end)

RegisterNetEvent('pis:breath')
AddEventHandler('pis:breath', function()
    if stoppedDriver and DoesEntityExist(stoppedDriver) then
        tpNotify("~b~Breathalyzer reading: ~w~0." .. tostring(breathNum))
    else
        tpNotify("~r~No stopped driver.")
    end
end)

RegisterNetEvent('pis:drug')
AddEventHandler('pis:drug', function()
    if stoppedDriver and DoesEntityExist(stoppedDriver) then
        tpNotify("~b~Drug test:~w~ Cannabis " .. tostring(cannabis) .. " | Cocaine " .. tostring(cocaine))
    else
        tpNotify("~r~No stopped driver.")
    end
end)

RegisterNetEvent('pis:askid')
AddEventHandler('pis:askid', function()
    if not stoppedDriver or not DoesEntityExist(stoppedDriver) then
        tpNotify("~r~No stopped driver.")
        return
    end
    driverQuestioned = true
    tpNotify("~o~Driver:~w~ My name is ~y~" .. tostring(driverName) .. "~w~, DOB ~b~" .. tostring(fullDriverDob))
end)

RegisterNetEvent('pis:exit')
AddEventHandler('pis:exit', function()
    if stoppedDriver and DoesEntityExist(stoppedDriver) then
        TaskLeaveVehicle(stoppedDriver, stoppedVeh, 0)
        tpNotify("Driver ordered out of the vehicle.")
    end
end)

RegisterNetEvent('pis:mount')
AddEventHandler('pis:mount', function()
    if stoppedDriver and DoesEntityExist(stoppedDriver) and stoppedVeh and DoesEntityExist(stoppedVeh) then
        TaskEnterVehicle(stoppedDriver, stoppedVeh, 5000, -1, 1.0, 1, 0)
        tpNotify("Driver ordered back into the vehicle.")
    end
end)

RegisterNetEvent('pis:release')
AddEventHandler('pis:release', function()
    TriggerEvent('po:release')
end)

RegisterNetEvent('pis:warn')
AddEventHandler('pis:warn', function()
    tpNotify("~o~Officer:~w~ I'm issuing you a warning today.")
    tpNotify("~o~Driver:~w~ Understood.")
end)

RegisterNetEvent('pis:drunk:q')
AddEventHandler('pis:drunk:q', function()
    tpNotify("~o~Driver:~w~ " .. ((breathNum > 0 and speech == "Aggressive") and "No, leave me alone." or "No officer."))
end)

RegisterNetEvent('pis:drug:q')
AddEventHandler('pis:drug:q', function()
    tpNotify("~o~Driver:~w~ " .. ((cannabis ~= "~g~Negative" or cocaine ~= "~g~Negative") and "I don't want to answer that." or "No officer."))
end)

RegisterNetEvent('pis:illegal:q')
AddEventHandler('pis:illegal:q', function()
    tpNotify("~o~Driver:~w~ " .. ((pedFlags ~= "~g~NONE") and "Nothing you need to worry about." or "No."))
end)

RegisterNetEvent('pis:search:q')
AddEventHandler('pis:search:q', function()
    tpNotify("~o~Driver:~w~ " .. ((speech == "Aggressive") and "I'd rather you didn't." or "Go ahead."))
end)

RegisterNetEvent('pis:hello')
AddEventHandler('pis:hello', function()
    tpNotify("~o~Officer:~w~ Good evening. I'm with TwoPoint AI Control.")
    tpNotify("~o~Driver:~w~ Hello officer.")
end)

RegisterNetEvent('po:release')
AddEventHandler('po:release', function()
    stopped = false
    mimicking = false
    following = false
    lockedin = false
    driverQuestioned = false
    fleeing = false
    if stoppedVeh and DoesEntityExist(stoppedVeh) then
        SetVehicleEngineOn(stoppedVeh, true, false, true)
    end
    clearTargetBlip()
    tpNotify("Vehicle released.")
end)

RegisterNetEvent('po:lock')
AddEventHandler('po:lock', function()
    lockedin = true
    notification = true
    if targetVeh and targetVeh ~= 0 then
        setTargetBlip(targetVeh)
    end
end)

RegisterNetEvent('po:unlock')
AddEventHandler('po:unlock', function()
    lockedin = false
    notification = false
    clearTargetBlip()
end)

RegisterNetEvent('po:stop')
AddEventHandler('po:stop', function()
    stopped = true
    fleeing = false
    mimicking = false
    following = false
    lockedin = false
    if stoppedVeh and DoesEntityExist(stoppedVeh) then
        SetVehicleEngineOn(stoppedVeh, false, false, true)
    end
end)

RegisterNetEvent('po:flee')
AddEventHandler('po:flee', function()
    tpNotify("Flee behavior disabled in this build.")
end)

RegisterNetEvent('po:shoot')
AddEventHandler('po:shoot', function()
    tpNotify("Shoot behavior disabled in this build.")
end)

RegisterCommand("lastalpr", function()
    if stoppedVeh and DoesEntityExist(stoppedVeh) then ALPR(stoppedVeh) end
end)

RegisterNetEvent('lastalpr')
AddEventHandler('lastalpr', function()
    if stoppedVeh and DoesEntityExist(stoppedVeh) then ALPR(stoppedVeh) end
end)

RegisterCommand("info", function()
    tpNotify("~w~Reg. Owner: ~y~" .. tostring(regOwner) .. "~w~\nReg. Year: ~y~" .. tostring(regYear) .. "~w~\nFlags: ~y~" .. tostring(flags))
end)

RegisterNetEvent('getInfo')
AddEventHandler('getInfo', function()
    randomProfile()
end)

RegisterNetEvent('radio')
AddEventHandler('radio', function()
    -- lightweight hook for menu calls
end)

function cancelEmote()
    ClearPedTasks(PlayerPedId())
end
