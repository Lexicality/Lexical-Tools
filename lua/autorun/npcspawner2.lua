--[[
    NPC Spawn Platforms V2
    Copyright (c) 2011-2016 Lex Robinson
    This code is freely available under the MIT License
--]]

local function printd(...)
    if (GetConVarNumber("developer") > 0) then
        print(...)
    end
end
local function printd2(...)
    if (GetConVarNumber("developer") > 1) then
        print(...)
    end
end

npcspawner = {
    debug = function(...)
        if (npcspawner.config.debug == 1) then
            printd("Spawn Platforms Debug ("..(SERVER and "server" or "client")..")",...);
        end
    end;
    debug2 = function(...)
        if (npcspawner.config.debug == 1) then
            printd2("Spawn Platforms Debug (Level 2) ("..(SERVER and "server" or "client")..")",...);
        end
    end;
    send = function(name, tab, who)
        net.Start(name);
        net.WriteTable(tab);
        if (CLIENT) then
            net.SendToServer();
        elseif (who) then
            net.Send(who);
        else
            net.Broadcast();
        end
    end;
    recieve = function(name, callback)
        net.Receive(name, function(len, who)
            callback(net.ReadTable(), who);
        end);
    end;
    -- Default config
    npcs = {};
    weps = {};
    config = {
        adminonly   = 0,
        callhooks   = 1,
        maxinplay   = 20,
        mindelay    = 0.1,
        debug       = 1,
        sanity      = 1,
    };
    legacy = {
        npc_citizen_medic   = "Medic";
        npc_citizen_rebel   = "Rebel";
        npc_citizen_dt      = "npc_citizen";
        npc_citizen_refugee = "Refugee";
        npc_combine_e       = "CombineElite";
        npc_combine_p       = "CombinePrison";
    };
};
