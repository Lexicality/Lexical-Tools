--[[
	NPC Spawn Platforms V2 - lua/autorun/npcspawner2.lua
    Copyright 2009-2017 Lex Robinson

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
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

local function svorcl()
    return SERVER and "SV" or "CL";
end

npcspawner = {
    debug = function(...)
        if (npcspawner.config.debug == 1) then
            printd("PLFM (" .. svorcl() .. "):", ...);
        end
    end;
    debug2 = function(...)
        if (npcspawner.config.debug == 1) then
            printd("PLFM L2 (" .. svorcl() .. "):", ...);
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
