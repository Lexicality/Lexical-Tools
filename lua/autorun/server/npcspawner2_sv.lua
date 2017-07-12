--[[
	NPC Spawn Platforms V2 - lua/autorun/server/npcspawner2_sv.lua
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
