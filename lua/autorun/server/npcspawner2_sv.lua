--[[
	NPC Spawn Platforms V2
	Copyright (c) 2011-2016 Lex Robinson
	This code is freely available under the MIT License
--]]
AddCSLuaFile("autorun/npcspawner2.lua");
AddCSLuaFile("autorun/client/npcspawner2_cl.lua");

local datapath = "npcspawner2"
if (file.IsDir(datapath, "DATA")) then
	local function readfile(fname)
		fname = datapath .. "/" .. fname .. ".txt";
		if (file.Exists(fname, "DATA")) then
			local data = util.JSONToTable(file.Read(fname, "DATA"));
			if (data and table.Count(data) > 0) then
				return data;
			end
		end
	end
	local cfg = readfile("config");
	if (cfg) then
		for key, value in pairs(cfg) do
			value = tonumber(value);
			if (value) then
				npcspawner.config[key] = value;
			end
		end
	end
end
local function writefile(fname, table)
	if (not file.IsDir(datapath, "DATA")) then
		file.CreateDir(datapath, "DATA");
	end
	fname = datapath .. "/" .. fname .. ".txt";
	file.Write(fname, util.TableToJSON(table));
end

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
	writefile("config", npcspawner.config);
end);

hook.Add("PlayerInitialSpawn", "NPCSpawner PlayerInitialSpawn", function(ply)
	npcspawner.send("NPCSpawner Config", npcspawner.config, ply);
end);

if (not ConVarExists("sbox_maxspawnplatforms")) then
	CreateConVar("sbox_maxspawnplatforms", 3);
end
cleanup.Register("sent_spawnplatform");
