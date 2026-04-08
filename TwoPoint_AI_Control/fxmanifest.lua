-- TwoPoint Development — Unified AI Control + Police Interaction
-- Stable traffic build for newer FiveM artifacts.

fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'TwoPoint_AI_Control'
description 'Unified AI density/dispatch + emergency cleanup + integrated police interaction for TwoPoint Development.'
author 'TwoPoint Development'
version '2.1.1'

client_scripts {
    'config.lua',
    'client.lua',

    'police/config_police.lua',
    'police/other/warmenu.lua',
    'police/other/loadouts_cl.lua',
    'police/other/menu_client.lua',
    'police/arrest/arr_client.lua',
    'police/pullover/pullover.lua',
    'police/addons/tow.lua'
}

server_scripts {
    'server.lua',
    'police/config_police.lua',
    'police/other/loadouts_sv.lua',
    'police/arrest/arr_server.lua',
    'police/pullover/po_server.lua'
}

files {
    'events.meta'
}

data_file 'EVENTS_OVERRIDE_FILE' 'events.meta'
