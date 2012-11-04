--[[
	NPC Spawn Platforms V2.1
    Copyright (c) 2011-2012 Lex Robinson
    This code is freely available under the MIT License
--]]
AddCSLuaFile("autorun/npcspawner2.lua");
AddCSLuaFile("autorun/client/npcspawner2_cl.lua");

local datapath = "npcspawner2"
if (not file.IsDir(datapath, "DATA")) then
    file.CreateDir(datapath, "DATA");
end

local function readfile(fname)
    fname = datapath .. "/" .. fname .. ".txt";
    if (file.Exists(fname, "DATA")) then
        local data = util.JSONToTable(file.Read(fname, "DATA"));
        if (data and table.Count(data) > 0) then
            return data;
        end
    end
end

npcspawner.npcs = readfile("npcs") or npcspawner.npcs;
npcspawner.weps = readfile("weps") or npcspawner.weps;

local cfg = readfile("config");
if (cfg) then
    for key, value in pairs(cfg) do
        value = tonumber(value);
        if (value) then
            npcspawner.config[key] = value;
        end
    end
end

util.AddNetworkString("NPCSpawner NPCs");
util.AddNetworkString("NPCSpawner Weps");
util.AddNetworkString("NPCSpawner Config");

for k, v in pairs(npcspawner.config) do
	umsg.PoolString(k)
	npcspawner.config[k] = tonumber(v);
end
concommand.Add("npcspawner_config", function(ply, _, args)
	local var, val = args[1], tonumber(args[2]);
	if (not (ply:IsAdmin() and var and val)) then return; end
	npcspawner.config[var] = val;
	umsg.Start("npcspawner_config");
	umsg.String(var);
	umsg.Float(val);
	umsg.End();
end);

hook.Add("PlayerInitialSpawn", "NPCSpawner PlayerInitialSpawn", function(ply)
	npcspawner.send("NPCSpawner NPCs",   npcspawner.npcs,   ply);
	npcspawner.send("NPCSpawner Weps",   npcspawner.weps,   ply);
	npcspawner.send("NPCSpawner Config", npcspawner.config, ply);
end);

if (not ConVarExists("sbox_maxspawnplatforms")) then
	CreateConVar("sbox_maxspawnplatforms", 3);
end
cleanup.Register("sent_spawnplatform");

-- This will allow admins to edit the npc/weapon lists in-game, when I add that feature.
--[[
npcspawner.recieve("NPCSpawner NPCs", function(data, ply)
	if (not ply:IsAdmin()) then return false end -- Someone might have fucked up the accept stream hook.
	if (table.Count(data) < 1) then return false end -- There must be data
	npcspawner.npcs = data;
	file.Write      ("npcspawner/npcs.txt", util.TableToKeyValues(npcspawner.npcs));
	npcspawner.debug("Just got new npc vars from", ply);
	npcspawner.send ("NPCSpawner NPCs", npcspawner.npcs);
end);

npcspawner.recieve("NPCSpawner Weps", function(data, ply)
	if (not ply:IsAdmin()) then return false end -- Someone might have fucked up the accept stream hook.
	if (table.Count(data) < 1) then return false end -- There must be data
	npcspawner.weps = data;
	file.Write      ("npcspawner/weps.txt", util.TableToKeyValues(npcspawner.weps));
	npcspawner.debug("Just got new weapon vars from", ply);
	npcspawner.send ("NPCSpawner Weps", npcspawner.weps);
end);
--]]
