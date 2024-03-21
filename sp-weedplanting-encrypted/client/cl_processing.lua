local props = {}
QBCore = exports['qb-core']:GetCoreObject()
local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function openHouseAnim()
    local ped = PlayerPedId()
    loadAnimDict("anim@heists@keycard@")
    TaskPlayAnim(ped, "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, 0, 0, 0)
    Wait(100)
    if Shared.WeedLab.EnableSound then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "LockerOpen", 0.1)
    end
    DoScreenFadeOut(800)
    Wait(850)
    DoScreenFadeIn(900)
    ClearPedTasks(ped)
end

local function SpawnWeedProcessProps()
    for k, v in pairs(Shared.ProcessingProps) do
        local prop = CreateObject(v.model, vector3(v.coords.x, v.coords.y, v.coords.z - 1.00))
        SetEntityHeading(prop, v.coords.w)
        FreezeEntityPosition(prop, true)
        props[#props + 1] = prop
    end
end

CreateThread(function()
    SpawnWeedProcessProps()
    exports.interact:AddInteraction({
        coords = vec3(1045.35, -3197.7, -38.15),
        distance = 4.0, -- optional
        interactDst = 2.0, -- optional
        name = 'Packet', -- optional
        options = {
             {
                label = _U('process_menu'),
                action = function()
                    TriggerEvent('sp-weedplanting:client:Menu')
                end,
            },
        }
    })
    exports.interact:AddInteraction({
        coords = vec3(1038.45, -3205.7, -38.15),
        distance = 4.0, -- optional
        interactDst = 2.0, -- optional
        name = "Joint",
        options = {
             {
                label = _U('process_menu'),
                action = function()
                    TriggerEvent('sp-weedplanting:client:CreateJoint')
                end,
            },
        }
    })
    exports.interact:AddInteraction({
        coords = vec3(1033.75, -3206.0, -38.2),
        distance = 4.0, -- optional
        interactDst = 2.0, -- optional
        name = "Joint",
        options = {
             {
                label = _U('process_menu'),
                action = function()
                    TriggerEvent('sp-weedplanting:client:CreateJoint')
                end,
            },
        }
    })
    exports.interact:AddInteraction({
        coords = vec3(-32.1, -1392.05, 29.75),
        distance = 2.0, -- optional
        interactDst = 1.0, -- optional
        name = "enter",
        options = {
             {
                label = 'Влизане',
                action = function()
                    TriggerEvent('sp-weedplanting:client:EnterLab')
                end,
            },
        }
    })
    exports.interact:AddInteraction({
        coords = vec3(1066.65, -3183.45, -38.85),
        distance = 4.0, -- optional
        interactDst = 2.0, -- optional
        name = "exit",
        options = {
             {
                label = 'Излизане',
                action = function()
                    TriggerEvent('sp-weedplanting:client:ExitLab')
                end,
            },
        }
    })
end)

RegisterNetEvent('sp-weedplanting:client:CreateJoint', function(data)
    lib.registerContext({
        id = "after_menu",
        title = _U('process_joint'),
        options = {{
            title = "Смелете малко трева.",
            icon = 'fa-solid fa-cubes-stacked',
            description = 'Имате нужда от \n Weed Grinder \n Пакетче 2G',
            event = 'sp-weedplanting:client:ProcessGrinder'
        }, {
            title = _U('create_joint'),
            icon = 'fa-solid fa-joint',
            description = 'Имате нужда от \n Зелена Плевел \n OCB 420',
            event = 'sp-weedplanting:client:joint'
        }}
    })
    lib.showContext('after_menu')
end)

RegisterNetEvent('sp-weedplanting:client:Menu', function()
    lib.registerContext({
        id = 'event_menu',
        title = 'Обработка на марихуана',
        -- menu = 'some_menu',
        options = {{
            title = _U('process_branch'),
            description = 'Имате нужда от клон/че с Трева',
            icon = 'fa-solid fa-cannabis',
            event = 'sp-weedplanting:client:ProcessBranch'
        }, {
            title = _U('drying_marijuana'),
            icon = 'fa-solid fa-group-arrows-rotate',
            description = 'Имате нужда от \n AK47 2g: x1 \n Празна торбичка: x1',
            event = 'sp-weedplanting:client:drying'
        }, {
            title = _U('pack_dry_weed'),
            icon = 'fa-solid fa-box',
            description = 'Имате нужда от \n AK47 2g: x20 \n Празен голям пакет :x1',
            event = 'sp-weedplanting:client:PackDryWeed'
        }}
    })
    lib.showContext('event_menu')
end)

-----------------------
-- New Grinder
-----------------------
RegisterNetEvent('sp-weedplanting:client:ProcessGrinder', function(data)
    QBCore.Functions.TriggerCallback('sp-weedplanting:server:HasGrinderr', function(returnGrinder)
        if returnGrinder then
            local itemsToCheck = Shared.Weedgrinder
            QBCore.Functions.TriggerCallback('sp-weedplanting:server:hasItemsWeedGrinder', function(hasItems, items)
                if hasItems then
                    local options = {}

                    for _, itemName in ipairs(items) do
                        table.insert(options, {
                            title = "Смилане на Тревата",
                            onSelect = function()
                                TriggerEvent('sp-weedplanting:client:inputProcessGrinder', itemName)
                            end
                        })
                    end
                    lib.registerContext({
                        id = 'weed-progress',
                        title = 'Обработка на клон/че',
                        options = options
                    })

                    lib.showContext('weed-progress')
                else
                    QBCore.Functions.Notify("Нямаш нищо за обработка в себе си!", "error",
                        5000)
                end
            end, itemsToCheck)
        else
            QBCore.Functions.Notify(_U('dont_have_enough_dryweed'), 'error', 2500)
        end
    end)
end)

RegisterNetEvent('sp-weedplanting:client:inputProcessGrinder', function(item)
    local quantityHas = exports.ox_inventory:Search('count', item)
    local input = lib.inputDialog('Въведи количество',
        {'Количество (Имате: ' .. quantityHas .. ')'})
    if not input then
        return
    end

    local quantity = tonumber(input[1])

    if quantity > quantityHas then
        QBCore.Functions.Notify("Нямате такова количество в себе си.", "error", 3000)
        return
    end
    local ped = PlayerPedId()
    local animationDuration = quantity * 5000
    local table = vector4(1341.99, 4391.8, 45.2, 153.95)
    TaskTurnPedToFaceCoord(ped, table, 1000)
    QBCore.Functions.Progressbar('weedbranch', _U('processing'), animationDuration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 8
    }, {}, {}, function()
        TriggerServerEvent('sp-weedplanting:server:WeedGrinder', item, quantity)
    end, function() -- Cancel
        QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
        ClearPedTasks(ped)
    end)
end)

-----------------------
-- NEW FUNCIOTNS OBRABOTKA
----------------------------
RegisterNetEvent('sp-weedplanting:client:ProcessBranch', function(data)
    local itemsToCheck = Shared.ItemsWeed
    QBCore.Functions.TriggerCallback('sp-weedplanting:server:hasItemsBranch', function(hasItems, items)
        if hasItems then
            local options = {}

            for _, itemName in ipairs(items) do
                table.insert(options, {
                    title = "Обработка на: Трева",
                    onSelect = function()
                        TriggerEvent('sp-weedplanting:client:inputsitems', itemName)
                    end
                })
            end
            lib.registerContext({
                id = 'weed-progress',
                title = 'Обработка на клон/че',
                options = options
            })

            lib.showContext('weed-progress')
        else
            QBCore.Functions.Notify("Нямаш нищо за обработка в себе си!", "error", 5000)
        end
    end, itemsToCheck)
end)

RegisterNetEvent('sp-weedplanting:client:inputsitems', function(item)
    local quantityHas = exports.ox_inventory:Search('count', item)
    local input = lib.inputDialog('Въведи количество',
        {'Количество (Имате: ' .. quantityHas .. ')'})
    if not input then
        return
    end

    local quantity = tonumber(input[1])

    if quantity > quantityHas then
        QBCore.Functions.Notify("Нямате такова количество в себе си.", "error", 3000)
        return
    end
    local ped = PlayerPedId()
    local table = vector4(1341.99, 4391.8, 45.2, 153.95)
    TaskTurnPedToFaceCoord(ped, table, 1000)
    local animationDuration = quantity * 5000
    QBCore.Functions.Progressbar('weedbranch', _U('processing_branch'), animationDuration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 8
    }, {}, {}, function()
        TriggerServerEvent('sp-weedplanting:server:ProcessBranch', item, quantity)
    end, function() -- Cancel
        QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
        ClearPedTasks(ped)
    end)
end)
----------------------------
-- END FUNCTUON OBRABOTKA
----------------------------

RegisterNetEvent('sp-weedplanting:client:drying', function()
    QBCore.Functions.TriggerCallback("sp-weedplanting:server:hasItemsdrying", function(hasItem)
        if not hasItem then
            QBCore.Functions.Notify(_U('dont_have_branch'), 'error', 2500)
            return
        end
        if hasItem then
            local ped = PlayerPedId()
            local table = vector4(1341.99, 4391.8, 45.2, 153.95)
            TaskTurnPedToFaceCoord(ped, table, 1000)
            QBCore.Functions.Progressbar('weedbranch', _U('processing_drying'), 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            }, {
                animDict = "mini@repair",
                anim = "fixing_a_ped",
                flags = 8
            }, {}, {}, function()
                TriggerServerEvent('sp-weedplanting:server:drying')
            end, function() -- Cancel
                QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
                ClearPedTasks(ped)
            end)
        end
    end)
end)

RegisterNetEvent('sp-weedplanting:client:joint', function()
    QBCore.Functions.TriggerCallback("sp-weedplanting:server:hasItemsjoint", function(hasItem)
        if not hasItem then
            QBCore.Functions.Notify(_U('dont_have_branch'), 'error', 2500)
            return
        end
        if hasItem then
            local ped = PlayerPedId()
            local table = vector4(1341.99, 4391.8, 45.2, 153.95)
            TaskTurnPedToFaceCoord(ped, table, 1000)
            QBCore.Functions.Progressbar('weedbranch', _U('processing_joint'), 12000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            }, {
                animDict = "mini@repair",
                anim = "fixing_a_ped",
                flags = 8
            }, {}, {}, function()
                TriggerServerEvent('sp-weedplanting:server:joint')
            end, function() -- Cancel
                QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
                ClearPedTasks(ped)
            end)
        end
    end)
end)

RegisterNetEvent('sp-weedplanting:client:PackDryWeed', function()
    QBCore.Functions.TriggerCallback("sp-weedplanting:server:hasItemsWeed", function(hasItem)
        if not hasItem then
            QBCore.Functions.Notify(_U('dont_have_enough_dryweed'), 'error', 2500)
            return
        end
        if hasItem then
            local ped = PlayerPedId()
            local table = vector4(1341.99, 4391.8, 45.2, 153.95)
            TaskTurnPedToFaceCoord(ped, table, 1000)
            QBCore.Functions.Progressbar('dryweed', _U('packaging_weed'), 12000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            }, {
                animDict = "mini@repair",
                anim = "fixing_a_ped",
                flags = 8
            }, {}, {}, function()
                TriggerServerEvent('sp-weedplanting:server:PackageWeed')
            end, function() -- Cancel
                QBCore.Functions.Notify(_U('canceled'), 'error', 2500)
                ClearPedTasks(ped)
            end)
        end
    end)
end)

RegisterNetEvent('sp-weedplanting:client:EnterLab', function()
    QBCore.Functions.TriggerCallback('sp-weedplanting:server:chekdiller',function(haskeysanddiller)
    if haskeysanddiller then
    local hasItem = QBCore.Functions.HasItem(Shared.LabkeyItem)
    if Shared.WeedLab.RequireKey then
        if not hasItem then
            QBCore.Functions.Notify(_U('dont_have_key'), 'error')
            return
        end
    end
    local ped = PlayerPedId()
    openHouseAnim()
    SetEntityCoords(ped, 1066.2, -3183.38, -39.16)
    SetEntityHeading(ped, 89.3)
else
QBCore.Functions.Notify('Няма как да влезнеш тук. Това не е мандра за всеки!', "primary", length)
end
end)
end)

RegisterNetEvent('sp-weedplanting:client:ExitLab', function()
    local hasItem = QBCore.Functions.HasItem(Shared.LabkeyItem)
    if Shared.WeedLab.RequireKey then
        if not hasItem then
            QBCore.Functions.Notify(_U('dont_have_key'), 'error')
            return
        end
    end
    local ped = PlayerPedId()
    openHouseAnim()
    SetEntityCoords(ped, -31.92, -1391.73, 29.41)
    SetEntityHeading(ped, 180.41)
end)
