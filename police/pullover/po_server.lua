RegisterServerEvent('ticket')
AddEventHandler('ticket', function(string)
  TriggerClientEvent('chatMessage', -1, string)
end)

local pisVersion = "1.0.5"

print("")
print("----------------[TwoPoint AI Control]----------------")
print("TwoPoint_AI:SYSTEM - Police Interaction Module loaded (TwoPoint AI Control core)")
print("TwoPoint_AI:SYSTEM - Running on TwoPoint AI Control v" .. pisVersion)
print("---------------------------------------")

TriggerClientEvent('chatMessage', -1, "^6TwoPoint AI Control^0 (TwoPoint AI Control v" .. pisVersion .. ") loaded.", { 0, 0, 0}, "")