local autopilotActive = false
local targetCoord = nil
local uiShowing = false
local hasShownUI = false  
local notifTimer = nil

local function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(false, true)
end

local function showUI()
    if not uiShowing then
        uiShowing = true
        SendNUIMessage({ action = "show", position = Config.NotificationPosition })
        notifTimer = Citizen.SetTimeout(Config.NotificationTime, function()
            hideUI()
        end)
    end
end

local function hideUI()
    if uiShowing then
        uiShowing = false
        SendNUIMessage({ action = "hide" })
        if notifTimer then
            Citizen.ClearTimeout(notifTimer)
            notifTimer = nil
        end
    end
end

local function PlayNativeSound(soundType)
    if soundType == "engaged" then
        PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
    elseif soundType == "disengaged" then
        PlaySoundFrontend(-1, "ERROR", "HUD_MINI_GAME_SOUNDSET", true)
    elseif soundType == "arrived" then
        PlaySoundFrontend(-1, "RACE_PLACED", "HUD_MINI_GAME_SOUNDSET", true)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local vehModel = GetEntityModel(veh)
            local modelName = GetDisplayNameFromVehicleModel(vehModel):lower()
            local allowedVehicle = false

            for _, allowedModel in ipairs(Config.AutopilotVehicles) do
                if modelName == allowedModel then
                    allowedVehicle = true
                    break
                end
            end

            if allowedVehicle and not autopilotActive then
                if not hasShownUI then
                    showUI()
                    hasShownUI = true
                end

                if IsControlJustReleased(0, 38) then
                    hideUI()
                    local blip = GetFirstBlipInfoId(8)
                    if DoesBlipExist(blip) then
                        local dest = GetBlipCoords(blip)
                        targetCoord = dest
                        autopilotActive = true
                        TaskVehicleDriveToCoord(ped, veh, dest.x, dest.y, dest.z, 20.0, 1, GetEntityModel(veh), 786603, 5.0)
                        ShowNotification("Autopilot engaged!")
                        PlayNativeSound("engaged")
                    else
                        ShowNotification("No waypoint set!")
                    end
                end
            else
                hideUI()
            end

            if autopilotActive then
                local pos = GetEntityCoords(veh)
                local dist = Vdist(pos.x, pos.y, pos.z, targetCoord.x, targetCoord.y, targetCoord.z)
                if dist < 10.0 then
                    autopilotActive = false
                    ShowNotification("Arrived at destination.")
                    PlayNativeSound("arrived")
                end

                if IsControlPressed(0, 71) or IsControlPressed(0, 72) or IsControlPressed(0, 59) or IsControlPressed(0, 60) then
                    autopilotActive = false
                    ClearPedTasks(ped)
                    ShowNotification("Autopilot disengaged due to manual control.")
                    PlayNativeSound("disengaged")
                end
            end

        else
            hideUI()
            hasShownUI = false  
            autopilotActive = false
        end
    end
end)
