local gavelCoords = vec3(338.34, -1621.68, 48.60 - 1)

CreateThread(function()
    exports.ox_target:addBoxZone({
        coords = gavelCoords,
        size = vec3(1, 1, 1),
        options = {
            {
                label = "Използвай Чукче",
                name = "judge_gavel",
                icon = "fa-solid fa-gavel",
                onSelect = function()
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 30, "gavel", 0.75)
                end
            }
        }
    })
end)