QBCore = exports['qb-core']:GetCoreObject()
PlayerJob = QBCore.Functions.GetPlayerData().job
local seedUsed = false

local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

local RayCastCamera = function(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerJob = {}
   -- clearWeedRun()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
   -- clearWeedRun()
end)

--- Events
RegisterNetEvent('sp-weedplanting:client:UseWeedSeed', function()
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then return end
    if seedUsed then return end

    seedUsed = true
    local ModelHash = Shared.WeedProps[1]
    RequestModel(ModelHash)
    while not HasModelLoaded(ModelHash) do Wait(0) end

    local hit, dest, _, _ = RayCastCamera(Shared.rayCastingDistance)
    local plant = CreateObject(ModelHash, dest.x, dest.y, dest.z + Shared.ObjectZOffset, false, false, false)
    SetEntityCollision(plant, false, false)
    SetEntityAlpha(plant, 150, true)

    local planted = false
    while not planted do
        Wait(0)
        hit, dest, _, _ = RayCastCamera(Shared.rayCastingDistance)

        if hit == 1 then
            SetEntityCoords(plant, dest.x, dest.y, dest.z + Shared.ObjectZOffset)

            if IsControlJustPressed(0, 38) then
                planted = true
                exports['qb-core']:KeyPressed(38)
                DeleteObject(plant)

                local ped = PlayerPedId()
                RequestAnimDict('amb@medic@standing@kneel@base')
                RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
                      not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do 
                    Wait(0)
                end

                TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)

                QBCore.Functions.Progressbar('spawn_plant', _U('place_sapling'), 2000, false, true, {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function() 
                    TriggerServerEvent('sp-weedplanting:server:CreateNewPlant', dest)
                    planted = false
                    seedUsed = false
                    ClearPedTasks(ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                end, function() 
                    QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
                    planted = false
                    seedUsed = false
                    ClearPedTasks(ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                end)
                
                return -- Използвайте return тук, за да предотвратите допълнителни проверки за събитието
            end
            
            -- [G] to cancel
            if IsControlJustPressed(0, 47) then
                exports['qb-core']:KeyPressed(47)
                planted = false
                seedUsed = false
                DeleteObject(plant)
                return
            end
        end
    end

    planted = false -- Нулиране на променливата след успешното поставяне или отмяна
    seedUsed = false
end)

RegisterNetEvent('sp-weedplanting:client:CheckPlant', function(data)
    local netId = NetworkGetNetworkIdFromEntity(data.entity)
    QBCore.Functions.TriggerCallback('sp-weedplanting:server:GetPlantData', function(result)
        if not result then return end
        if result.health == 0 then -- Destroy plant
            lib.registerContext({
                id = 'checkplant',
                title = _U('plant_header'),
                options = {
                    {
                        title = _U('clear_plant_header'),
                        description = _U('clear_plant_text'),
                        icon = 'fas fa-skull-crossbones',
                        event = 'sp-weedplanting:client:ClearPlant',
                        args = data.entity
                    },
                }
              })
             
            lib.showContext('checkplant')
        elseif result.growth == 100 then -- Harvest
            if PlayerJob.type == Shared.CopJob and PlayerJob.onduty then
                lib.registerContext({
                    id = 'plant_header',
                    title = _U('plant_header'),
                    options = {
                        {
                            title = 'Стадий: ' .. result.stage .. ' - Състояние: ' .. result.health,
                            description = _U('ready_for_harvest'),
                            icon = 'fas fa-scissors',
                            event = 'sp-weedplanting:client:HarvestPlant',
                            args = data.entity
                        },
                        {
                            title = _U('destroy_plant'),
                            description = _U('police_burn'),
                            icon = 'fas fa-fire',
                            event = 'sp-weedplanting:client:PoliceDestroy',
                            args = data.entity
                        },
                    }
                  })
                 
                lib.showContext('plant_header')
            else
                lib.registerContext({
                    id = 'plant_header2',
                    title = _U('plant_header'),
                    options = {
                        {
                            title = 'Стадий: ' .. result.stage .. ' - Състояние: ' .. result.health,
                            description = _U('ready_for_harvest'),
                            icon = 'fas fa-scissors',
                            event = 'sp-weedplanting:client:HarvestPlant',
                            args = data.entity
                        },
                    }
                  })
                 
                lib.showContext('plant_header2')
            end
        elseif result.gender == 'female' then -- Option to add male seed
            if PlayerJob.type == Shared.CopJob and PlayerJob.onduty then
                lib.registerContext({
                    id = 'plant_header3',
                    title = _U('plant_header'),
                    options = {
                        {
                            title = 'Разтеж: ' .. result.growth .. '%' .. ' - Стадий: ' .. result.stage,
                            txt = 'Състояние: ' .. result.health,
                            icon = 'fas fa-chart-simple',
                        },
                        {
                            title = _U('destroy_plant'),
                            description = _U('police_burn'),
                            icon = 'fas fa-fire',
                            event = 'sp-weedplanting:client:PoliceDestroy',
                            args = data.entity
                        },
                    }
                  })
                 
                lib.showContext('plant_header3')
            else
                lib.registerContext({
                    id = 'plant_header4',
                    title = _U('plant_header'),
                    options = {
                        {
                            title = 'Разтеж: ' .. result.growth .. '%' .. ' - Стадий: ' .. result.stage,
                            txt = 'Състояние: ' .. result.health,
                            icon = 'fas fa-chart-simple',
                        },
                        {
                            title = 'Вода: ' .. result.water .. '%',
                            txt = _U('add_water'),
                            icon = 'fas fa-shower',
                            event = 'sp-weedplanting:client:GiveWater',
                            args = data.entity
                        },
                        {
                            title = 'Тор: ' .. result.fertilizer .. '%',
                            description = _U('add_fertilizer'),
                            icon = 'fab fa-nutritionix',
                            event = 'sp-weedplanting:client:GiveFertilizer',
                            args = data.entity
                        },
                        {
                            title = 'Пол: ' .. result.gender,
                            description = _U('add_mseed'),
                            icon = 'fas fa-shower',
                            event = 'sp-weedplanting:client:AddMaleSeed',
                            args = data.entity
                        },
                        {
                            title = _U('destroy_plant'),
                            description = _U('police_burn'),
                            icon = 'fas fa-fire',
                            event = 'sp-weedplanting:client:PoliceDestroy',
                            args = data.entity
                        },
                    }
                  })
                 
                lib.showContext('plant_header4')
            end
        else -- No option to add male seed
            if PlayerJob.type == Shared.CopJob and PlayerJob.onduty then
                lib.registerContext({
                    id = 'plant_header5',
                    title = _U('plant_header'),
                    options = {
                        {
                            title = 'Разтеж: ' .. result.growth .. '%' .. ' - Стадий: ' .. result.stage,
                            txt = 'Състояние: ' .. result.health,
                            icon = 'fas fa-chart-simple',
                        },
                        {
                            title = _U('destroy_plant'),
                            description = _U('police_burn'),
                            icon = 'fas fa-fire',
                            event = 'sp-weedplanting:client:PoliceDestroy',
                            args = data.entity
                        },
                    }
                  })
                 
                lib.showContext('plant_header5')
            else
                lib.registerContext({
                    id = 'plant_header6',
                    title = _U('plant_header'),
                    options = {
                        {
                            title = 'Разтеж: ' .. result.growth .. '%' .. ' - Стадий: ' .. result.stage,
                            txt = 'Състояние: ' .. result.health,
                            icon = 'fas fa-chart-simple',
                        },
                        {
                            title = 'Вода: ' .. result.water .. '%',
                            txt = _U('add_water'),
                            icon = 'fas fa-shower',
                            event = 'sp-weedplanting:client:GiveWater',
                            args = data.entity
                        },
                        {
                            title = 'Тор: ' .. result.fertilizer .. '%',
                            description = _U('add_fertilizer'),
                            icon = 'fab fa-nutritionix',
                            event = 'sp-weedplanting:client:GiveFertilizer',
                            args = data.entity
                        },
                        {
                            title = 'Пол: ' .. result.gender,
                            description = _U('add_mseed'),
                            icon = 'fas fa-shower',
                            event = 'sp-weedplanting:client:AddMaleSeed',
                            args = data.entity
                        },
                    }
                  })
                 
                lib.showContext('plant_header6')
            end
        end
    end, netId)
end)

RegisterNetEvent('sp-weedplanting:client:ClearPlant', function(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0) 
    end
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)

    QBCore.Functions.Progressbar('clear_plant', _U('clear_plant'), 8500, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        TriggerServerEvent('sp-weedplanting:server:ClearPlant', netId)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end, function()
        QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end)
end)

RegisterNetEvent('sp-weedplanting:client:HarvestPlant', function(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local ped = PlayerPedId()
    QBCore.Functions.TriggerCallback("sp-weedplanting:server:itemsHarvestPlant", function(hasItem)
        if not hasItem then
            QBCore.Functions.Notify(_U('dont_have_branch'), 'error', 2500)
            return
        end
        if hasItem then
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0) 
    end
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)

    QBCore.Functions.Progressbar('harvest_plant', _U('harvesting_plant'), 8500, false, true, {
        disableMovement = true, 
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        TriggerServerEvent('sp-weedplanting:server:HarvestPlant', netId)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end, function()
        QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end)
        end
    end)
end)

RegisterNetEvent('sp-weedplanting:client:PoliceDestroy', function(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(500)
    ClearPedTasks(ped)
    TriggerServerEvent('sp-weedplanting:server:PoliceDestroy', netId)
end)

RegisterNetEvent('sp-weedplanting:client:FireGoBrrrrrrr', function(coords)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    if #(pedCoords - vector3(coords.x, coords.y, coords.z)) > 300 then return end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    SetPtfxAssetNextCall('core')
    local effect = StartParticleFxLoopedAtCoord('ent_ray_paleto_gas_flames', coords.x, coords.y, coords.z + 0.5, 0.0, 0.0, 0.0, 0.6, false, false, false, false)
    Wait(Shared.FireTime)
    StopParticleFxLooped(effect, 0)
end)

RegisterNetEvent('sp-weedplanting:client:GiveWater', function(entity)
    QBCore.Functions.TriggerCallback("sp-weedplanting:server:WaterCan", function(hasItem)
    if not hasItem then
        QBCore.Functions.Notify(_U('missing_water'), 'error', 2500)
        return
    end
    if hasItem then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local model = `prop_wateringcan`
        TaskTurnPedToFaceEntity(ped, entity, 1.0)
        RequestModel(model)
        RequestNamedPtfxAsset('core')
        while not HasModelLoaded(model) or not HasNamedPtfxAssetLoaded('core') do Wait(0) end
        SetPtfxAssetNextCall('core')
        local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
        local effect = StartParticleFxLoopedOnEntity('ent_sht_water', created_object, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)
        QBCore.Functions.Progressbar('weedplanting_water', _U('watering_plant'), 6000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = 'weapon@w_sp_jerrycan',
            anim = 'fire',
            flags = 1,
        }, {}, {}, function()
            TriggerServerEvent('sp-weedplanting:server:GiveWater', netId)
            ClearPedTasks(ped)
            DeleteEntity(created_object)
            StopParticleFxLooped(effect, 0)
        end, function()
            ClearPedTasks(ped)
            DeleteEntity(created_object)
            StopParticleFxLooped(effect, 0)
            QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
        end)
    end
end)
end)

RegisterNetEvent('sp-weedplanting:client:OpenFillWaterMenu', function()
    lib.registerContext({
        id = 'plant_header3',
        title = _U('empty_watering_can_header'),
        options = {
            {
                title = _U('fill_can_header'),
                txt = _U('fill_can_text'),
                icon = 'fa-solid fa-oil-can',
                event = 'sp-weedplanting:client:FillWater',
            },
        }
    })
     
    lib.showContext('plant_header3')
end)

RegisterNetEvent('sp-weedplanting:client:FillWater', function()
QBCore.Functions.TriggerCallback("sp-weedplanting:server:fillwater", function(hasItem) 
    if not hasItem then
        QBCore.Functions.Notify(_U('missing_filling_water'), 'error', 2500)
        return
    end
    local ped = PlayerPedId()
    local table = vector4(1349.89, 4388.99, 44.34, 352.84)

    TaskTurnPedToFaceCoord(ped, table, 1000)
    QBCore.Functions.Progressbar('filling_water', _U('filling_water'), 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, { animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", anim = "machinic_loop_mechandplayer", flags = 8, }, {}, {}, function()
        TriggerServerEvent('sp-weedplanting:server:GetFullWateringCan')
    end, function() -- Cancel
        QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
        end)
    end)
end)

RegisterNetEvent('sp-weedplanting:client:GiveFertilizer', function(entity)
    QBCore.Functions.TriggerCallback("sp-weedplanting:server:giveferilize", function(hasItem) 
        if not hasItem then
            QBCore.Functions.Notify(_U('missing_fertilizer'), 'error', 2500)
            return
        end
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local model = `w_am_jerrycan_sf`
        TaskTurnPedToFaceEntity(ped, entity, 1.0)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
        QBCore.Functions.Progressbar('weedplanting_fertilizer', _U('fertilizing_plant'), 6000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = 'weapon@w_sp_jerrycan',
            anim = 'fire',
            flags = 1,
        }, {}, {}, function()
            TriggerServerEvent('sp-weedplanting:server:GiveFertilizer', netId)
            ClearPedTasks(ped)
            DeleteEntity(created_object)
        end, function()
            ClearPedTasks(ped)
            DeleteEntity(created_object)
            QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
        end)
    end)
end)

RegisterNetEvent('sp-weedplanting:client:AddMaleSeed', function(entity)
    QBCore.Functions.TriggerCallback("sp-weedplanting:server:maleseed", function(hasItem) 
        if not hasItem then
            QBCore.Functions.Notify(_U('missing_mseed'), 'error', 2500)
            return
        end
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local ped = PlayerPedId()
        TaskTurnPedToFaceEntity(ped, entity, 1.0)
        RequestAnimDict('amb@medic@standing@kneel@base')
        RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
        while 
            not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
            not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
        do 
            Wait(0) 
        end
        TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
        TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)

        QBCore.Functions.Progressbar('add_maleseed', _U('adding_male_seed'), 8500, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            TriggerServerEvent('sp-weedplanting:server:AddMaleSeed', netId)
            ClearPedTasks(ped)
            RemoveAnimDict('amb@medic@standing@kneel@base')
            RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
        end, function()
            QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
            ClearPedTasks(ped)
            RemoveAnimDict('amb@medic@standing@kneel@base')
            RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
        end)
    end)
end)
RegisterNetEvent('sp-weedplanting:client:OpenBox', function()
    local ox_inventory = exports.ox_inventory
    local stash = {
        id = 'weed_stash',
        label = 'Weed House Stash',
        slots = 60,
        weight = 60000,
        owner = true
    }

    if ox_inventory:openInventory('stash', stash.id) == false then
        ox_inventory:openInventory('stash', stash.id)
    end
end)

RegisterNetEvent('sp-weedplanting:client:shop', function(data)
    QBCore.Functions.TriggerCallback('sp-weedplanting:server:chekdiller', function(DellerShops)
        if DellerShops then
            local event = "inventory:server:OpenInventory"
            exports.ox_inventory:openInventory('shop', {
                type = 'weedshop'
            })
            TriggerServerEvent(event, "shop", "weedshop", Shared.Items)
        else
            QBCore.Functions.Notify('Не може да разговаряш с мен', "error")
        end
    end)
end)


RegisterNetEvent('sp-weedplanting:client:why', function(data)
    TriggerServerEvent('sp-weedplanting:server:why')
end)

--- Threads
CreateThread(function()
    exports.interact:AddInteraction({
        coords = vec3(1042.65, -3206.15, -38.25),
        distance = 4.0, -- optional
        interactDst = 2.0, -- optional
        name = 'Water', -- optional
        options = {
             {
                label = _U('fill_can_header'),
                action = function()
                    TriggerEvent('sp-weedplanting:client:OpenFillWaterMenu')
                end,
            },
        }
    })
    exports.interact:AddInteraction({
        coords = vec3(-2044.75, 3410.0, 30.5),
        distance = 4.0, -- optional
        interactDst = 2.0, -- optional
        name = 'Water2', -- optional
        options = {
             {
                label = _U('fill_can_header'),
                action = function()
                    TriggerEvent('sp-weedplanting:client:OpenFillWaterMenu')
                end,
            },
        }
    })
    exports.interact:AddInteraction({
        coords = vec3(1038.8, -3198.9, -38.25),
        distance = 4.0, -- optional
        interactDst = 2.0, -- optional
        name = 'Stash', -- optional
        options = {
             {
                label = _U('open_box'),
                action = function()
                    TriggerEvent('sp-weedplanting:client:OpenBox')
                end,
            },
        }
    })
    
    local options = {
        { targetIcon = "fa-solid fa-cannabis", distance = 2.3},
        {
            event = 'sp-weedplanting:client:CheckPlant',
            icon = 'fas fa-cannabis',
            distance = 1.5,
            label = _U('check_plant')
        }
    }
    exports.ox_target:addModel(Shared.WeedProps, options) 
end)
