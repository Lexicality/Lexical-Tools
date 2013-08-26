--[[
    NPC Spawn Platforms V2.1
    Copyright (c) 2011-2012 Lex Robinson
    This code is freely available under the MIT License
--]]

function printd(...)
    if (GetConVarNumber("developer") > 0) then
        print(...)
    end
end
function printd2(...)
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
    npcs = {
        npc_headcrab        = "Headcrab",
        npc_headcrab_poison = "Headcrab, Poison",
        npc_headcrab_fast   = "Headcrab, Fast",
        npc_zombie          = "Zombie",
        npc_poisonzombie    = "Zombie, Poison",
        npc_fastzombie      = "Zombie, Fast",
        npc_antlion         = "Antlion",
        npc_antlionguard    = "Antlion Guard",
        npc_crow            = "Crow",
        npc_pigeon          = "Pigeon",
        npc_seagull         = "Seagull",
        npc_citizen         = "Citizen",
        npc_citizen_refugee = "Citizen, Refugee",
        npc_citizen_dt      = "Citizen, Downtrodden",
        npc_citizen_rebel   = "Rebel",
        npc_citizen_medic   = "Rebel Medic",
        npc_combine_s       = "Combine Soldier",
        npc_combine_p       = "Combine, Prison",
        npc_combine_e       = "Combine, Elite",
        npc_metropolice     = "Metrocop",
        npc_manhack         = "Manhack",
        npc_rollermine      = "Rollermine",
        npc_vortigaunt      = "Vortigaunt"
    };
    weps = {
        weapon_crowbar          = "Crowbar",
        weapon_stunstick        = "Stunstick",
        weapon_pistol           = "Pistol",
        weapon_alyxgun          = "Alyx's Gun",
        weapon_smg1             = "SMG",
        weapon_ar2              = "AR2",
    --  weapon_rpg              = "RPG", -- RPG doesn't work D:
        weapon_shotgun          = "Shotgun",
        weapon_annabelle        = "Anabelle",
        weapon_citizenpackage   = "Package",
        weapon_citizensuitcase  = "Suitcase",
        weapon_none             = "None",
        weapon_rebel            = "Random Rebel Weapon",
        weapon_combine          = "Random Combine Weapon",
        weapon_citizen          = "Random Citizen Weapon"
    };
    config = {
        adminonly   = 0,
        callhooks   = 1,
        maxinplay   = 20,
        mindelay    = 0.1,
        debug       = 1,
    };
};
-- Stuff that required ep1/ep2 to be mounted
if (util.IsValidModel("models/hunter.mdl")) then
    npcspawner.npcs["npc_hunter"] = "Hunter";
end if (util.IsValidModel("models/zombie/zombie_soldier.mdl")) then
    npcspawner.npcs["npc_zombine"] = "Zombine";
end
