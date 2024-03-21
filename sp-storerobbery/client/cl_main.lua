local RobbedRegisters = {}
local RobbedSafes = {}
local OpenedSafe = {}
local QBCore = exports['qb-core']:GetCoreObject()
local registerhack = true
local ShowNumber = false

PlayAnimation = function(ped, dict, anim, settings)
	if dict then
	     CreateThread(function()
	     RequestAnimDict(dict)

	     while not HasAnimDictLoaded(dict) do
		   Wait(100)
	     end

	     if settings == nil then
		   TaskPlayAnim(ped, dict, anim, 1.0, -1.0, 1.0, 0, 0, 0, 0, 0)
	     else
		   local speed = 1.0
		   local speedMultiplier = -1.0
		   local duration = 1.0
		   local flag = 0
		   local playbackRate = 0

		   if settings["speed"] then
			 speed = settings["speed"]
		   end

		   if settings["speedMultiplier"] then
			 speedMultiplier = settings["speedMultiplier"]
		   end

		   if settings["duration"] then
			 duration = settings["duration"]
		   end

		   if settings["flag"] then
			 flag = settings["flag"]
		   end

		   if settings["playbackRate"] then
			 playbackRate = settings["playbackRate"]
		   end

		   TaskPlayAnim(ped, dict, anim, speed, speedMultiplier, duration, flag, playbackRate, 0, 0, 0)
	     end

	     RemoveAnimDict(dict)
	     end)
	else
	     TaskStartScenarioInPlace(ped, anim, 0, true)
	end
end

CreateThread(function()
    TriggerServerEvent('sp-storerobbery:Server:GetSave')
    for i, Shop in pairs(Shops) do
        AddTargetBox('ShopSafe'..i, Shop.safe, {
            {targetIcon = "fas fa-sack-dollar", distance = 2.0},
            {
                icon = 'fas fa-laptop',
                label = 'Отвори сейфа',
                item = Config.safe_loot.item_needed,
                items = Config.safe_loot.item_needed,
                debug = Config.debug,
                distance = 1.5,
                action = function()
                    Config.Dispatch('safe', Shop.safe.xyz)
                    local coordsID = tostring(math.floor(Shop.safe.x+Shop.safe.y+Shop.safe.z))
                    if RobbedSafes[coordsID] then return Config.Notify('Някой те изпревари балъче','error') end
                    local Time = math.random(3000)
                    StoreRobAnim(Time)
                    local numberPromise = promise.new()

                    QBCore.Functions.TriggerCallback('sp-storerobbery:server:code', function(cb)
                        numberPromise:resolve(cb)
                    end, nil)

                    local serverNumber = Citizen.Await(numberPromise)

                    if exports['sp-minigame']:KeyPad(serverNumber, 5000) then
                        --print(numberval)
                        local removeItem = false
                        if Config.safe_loot.remove_item_fail ~= false then
                            if type(Config.safe_loot.remove_item_fail) == 'table' and math.random(Config.safe_loot.remove_item_fail[1], Config.safe_loot.remove_item_fail[2]) == 1 then
                                removeItem = true
                            elseif type(Config.safe_loot.remove_item_fail) == 'bool' then
                                removeItem = true
                            end
                        end
                        Config.Notify('Изчакай 3 мунути за да се отвори сейфът' , 'success')
                        TriggerServerEvent('sp-storerobbery:Server:SafeHackDone', i, coordsID, removeItem)
                        TriggerServerEvent('sp-storerobbery:Server:RemoveItem', Config.safe_loot.item_needed)
                    else
                        --print(numberval)
                        if Config.safe_loot.remove_item_fail ~= false then
                            if type(Config.safe_loot.remove_item_fail) == 'table' and math.random(Config.safe_loot.remove_item_fail[1], Config.safe_loot.remove_item_fail[2]) == 1 then
                                TriggerServerEvent('sp-storerobbery:Server:RemoveItem', Config.safe_loot.item_needed)
                            elseif type(Config.safe_loot.remove_item_fail) == 'bool' then
                                TriggerServerEvent('sp-storerobbery:Server:RemoveItem', Config.safe_loot.item_needed)
                            end
                        end
                    end
                end,
            },
            {
                icon = 'fas fa-sack-dollar',
                label = 'Вземи нещата от сейфа',
                distance = 2.0,
                action = function()
                    QBCore.Functions.Progressbar("zfsearch_register", 'Охх парички, парички', Config.Progresstimes('safe'), false, false, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    },{
                        animDict = 'oddjobs@shop_robbery@rob_till',
                        anim = 'loop',
                        flags = 1,
                        },
                    {
                          model = 'bkr_prop_money_unsorted_01',
                          bone = 18905,
                          coords = vec3(0.1, 0.02, 0.05),
                          rotation = vec3(10.0, 0.0, 0.0),
                        },
                    {
                          model = 'bkr_prop_money_unsorted_01',
                          bone = 58866,
                          coords = vec3(0.02, -0.08, 0.001),
                          rotation = vec3(-100.0, 0.0, 0.0),
                        }, function()
                        TriggerServerEvent('sp-storerobbery:Server:Reward', 'safe', i)
                    end)
                end,
                canInteract = function()
                    return OpenedSafe[i]
                end,
            }
        })
    end
    AddTargetModel('prop_till_01', {
        {targetIcon = "fas fa-sack-dollar", distance = 2.0},
        {
            icon = 'fas fa-sack-dollar',
            label = "Разбий касата",
            item = Config.register_loot.item_needed,
            items = Config.register_loot.item_needed,
            distance = 1.5,
            action = function(entity)
                if type(entity) == 'table' then entity = entity.entity end
                local coords = GetEntityCoords(entity)
                Config.Dispatch('register', coords)
                local coordsID = tostring(math.floor(coords.x+coords.y+coords.z))
                if RobbedRegisters[coordsID] then return Config.Notify('Касата е разбита','error') end
                if math.abs(GetEntityHeading(entity)-GetEntityHeading(PlayerPedId())) > 70 then return Config.Notify('Не си зад гишето!','error') end
                local Time = math.random(55000)
                StoreRobAnim(Time)
                registerhack = false
                if exports['sp-minigame']:MemoryCards('medium') then
                    local removeItem = false
                    if Config.register_loot.remove_item_fail ~= false then
                        if type(Config.register_loot.remove_item_fail) == 'table' and math.random(Config.register_loot.remove_item_fail[1], Config.register_loot.remove_item_fail[2]) == 1 then
                            removeItem = true
                        elseif type(Config.register_loot.remove_item_fail) == 'bool' then
                            removeItem = true
                        end
                    end
                    QBCore.Functions.Progressbar("zfsearch_register", 'Охх парички, парички', Config.Progresstimes('register'), false, false, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    },{
                        animDict = 'oddjobs@shop_robbery@rob_till',
                        anim = 'loop',
                        flags = 1,
                        },
                    {
                          model = 'bkr_prop_money_unsorted_01',
                          bone = 18905,
                          coords = vec3(0.1, 0.02, 0.05),
                          rotation = vec3(10.0, 0.0, 0.0),
                        },
                    {
                          model = 'bkr_prop_money_unsorted_01',
                          bone = 58866,
                          coords = vec3(0.02, -0.08, 0.001),
                          rotation = vec3(-100.0, 0.0, 0.0),
                        }, function()
                        TriggerServerEvent('sp-storerobbery:Server:Reward', 'register', coordsID, removeItem)
                        if not ShowNumber then
                            QBCore.Functions.TriggerCallback('sp-storerobbery:server:code', function(cb)
                                --print('Кодът е '..cb)
                                exports['sp-minigame']:ShowNumber(cb, 4000) --ShowNumber(code(number), time(milliseconds))
                            end, 'create')
                        ShowNumber = true
                        end
                        registerhack = true
                    end)
                else
                    if Config.register_loot.remove_item_fail ~= false then
                        if type(Config.register_loot.remove_item_fail) == 'table' and math.random(Config.register_loot.remove_item_fail[1], Config.register_loot.remove_item_fail[2]) == 1 then
                            TriggerServerEvent('sp-storerobbery:Server:RemoveItem', Config.register_loot.item_needed)
                            registerhack = true
                        elseif type(Config.register_loot.remove_item_fail) == 'bool' then
                            TriggerServerEvent('sp-storerobbery:Server:RemoveItem', Config.register_loot.item_needed)
                            registerhack = true
                        end
                    end
                end
            end,
            canInteract = function(entity)
                for i, shop in pairs(Shops) do
                    if #(GetEntityCoords(entity) - shop.counter) < 10.0 then
                        return true and registerhack
                    end
                end
                return false
            end,
        }
    })
end)

RegisterNetEvent('sp-storerobbery:Client:UpdateRegisters', function(NewData)
    RobbedRegisters = NewData
end)

RegisterNetEvent('sp-storerobbery:Client:UpdateSafes', function(NewData)
    RobbedSafes = NewData
end)

RegisterNetEvent('sp-storerobbery:Client:UpdateshowCode', function(NewData)
    ShowNumber = NewData
end)

RegisterNetEvent('sp-storerobbery:Client:UpdateSafeDoor', function(ShopID, Bool)
    OpenedSafe[ShopID] = Bool
end)

function AddTargetBox(id, coords, options)
    if Config.target.script == 'qb-target' then
        exports[Config.target.name or 'qb-target']:AddBoxZone(id, coords.xyz, 1.0, 1.0, {
            name = id,
            heading = coords.w,
            debugPoly = Config.debug,
            minZ = coords.z-1.0,
            maxZ = coords.z+1.5,
        }, {
            options = options,
            distance = 2.5,
        })
    elseif Config.target.script == 'ox_target' then
        for i, option in pairs(options) do option.onSelect = option.action end
        exports[Config.target.name or 'ox_target']:addBoxZone({
            name = id,
            debug = Config.debug,
            coords = vec3(coords.x, coords.y, coords.z),
            size = vec3(1.0, 1.0, 1.0),
            rotation = coords.w,
            options = options,
        })
    end
end

function AddTargetModel(model, options)
    if Config.target.script == 'qb-target' then
        exports[Config.target.name or 'qb-target']:AddTargetModel(model,{
            options = options,
            distance = 2.0
        })
    elseif Config.target.script == 'ox_target' then
        for i, option in pairs(options) do option.onSelect = option.action end
        exports[Config.target.name or 'ox_target']:addModel(model, options)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i, location in pairs(Shops) do
        if Config.target.script == 'qb-target' then
            exports[Config.target.name or 'qb-target']:RemoveZone('ShopSafe'..i)
        elseif Config.target.script == 'ox_target' then
            exports[Config.target.name or 'ox_target']:removeZone('ShopSafe'..i)
        end
    end
end)

function StoreRobAnim(time)
    time = time / 1000
    local dict = "veh@break_in@0h@p_m_one@"
  
      RequestAnimDict(dict)
      while not HasAnimDictLoaded(dict) do
          Wait(0)
      end
    TaskPlayAnim(PlayerPedId(), "veh@break_in@0h@p_m_one@", "low_force_entry_ds" ,3.0, 3.0, -1, 16, 0, false, false, false)
    OpeningSomething = true
    CreateThread(function()
        while OpeningSomething do
            if math.random(1, 50) <= 20 then
              TriggerServerEvent('hud:Server:GainStress', 1)
            end
            TaskPlayAnim(PlayerPedId(), "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 3.0, 3.0, -1, 16, 0, 0, 0, 0)
            Wait(2000)
            time = time - 2
            if time <= 0 then
                OpeningSomething = false
                StopAnimTask(PlayerPedId(), "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 1.0)
            end
        end
    end)
end

-- RegisterCommand('testprogresbar',function(source,args) 
--     QBCore.Functions.Progressbar("zfsearch_register", 'Охх парички, парички', '5000', false, false, {
--         disableMovement = true,
--         disableCarMovement = true,
--         disableMouse = false,
--         disableCombat = true,
--     },{
--         animDict = 'oddjobs@shop_robbery@rob_till',
--         anim = 'loop',
--         flags = 1,
--         },
--     {
--           model = 'bkr_prop_money_unsorted_01',
--           bone = 18905,
--           coords = vec3(0.1, 0.02, 0.05),
--           rotation = vec3(10.0, 0.0, 0.0),
--         },
--     {
--           model = 'bkr_prop_money_unsorted_01',
--           bone = 58866,
--           coords = vec3(0.02, -0.08, 0.001),
--           rotation = vec3(-100.0, 0.0, 0.0),
--         }, function()
--         TriggerServerEvent('sp-storerobbery:Server:Reward', 'register', coordsID, removeItem)
    
--         if Config.MachRandomRegister == 1 then
--             exports['sp-minigame']:ShowNumber(Config.Code, 3000)
--         else
--            -- print('Опитай другата каса')
--         end
--     end)
-- end)

-- RegisterCommand('showcode',function(source,args) 

--     QBCore.Functions.TriggerCallback('sp-storerobbery:server:code', function(cb)
--         --print('Кодът е '..cb)
--         exports['sp-minigame']:ShowNumber(cb, 9000) --ShowNumber(code(number), time(milliseconds))
--     end, 'create')
-- end)