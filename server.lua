-- TwoPoint AI Control - server side helpers (LEO permission)

RegisterNetEvent('TwoPoint_AI:RequestLEOStatus')
AddEventHandler('TwoPoint_AI:RequestLEOStatus', function()
    local src = source
    local ok = IsPlayerAceAllowed(src, 'group.LEO')
    TriggerClientEvent('TwoPoint_AI:SetLEOStatus', src, ok)
end)
