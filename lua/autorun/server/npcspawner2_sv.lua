--[[
	NPC Spawn Platforms V2.1
	~ Lexi ~
--]]
AddCSLuaFile("autorun/npcspawner2.lua");
AddCSLuaFile("autorun/client/npcspawner2_cl.lua");
-- I'd rather use glon and sql, but you have to make this shit accessable yo.
if (not file.IsDir("npcspawner2")) then
	file.CreateDir("npcspawner2");
end
if (file.Exists("npcspawner2/npcs.txt")) then
	local data = util.KeyValuesToTable(file.Read("npcspawner/npcs.txt"));
	if (table.Count(data) > 0) then
		npcspawner.npcs = data;
	end
end
if (not npcspawner.npcs) then
	npcspawner.npcs = {
		npc_headcrab		= "Headcrab",
		npc_headcrab_poison	= "Headcrab, Poison",
		npc_headcrab_fast	= "Headcrab, Fast",
		npc_zombie			= "Zombie",
		npc_poisonzombie	= "Zombie, Poison",
		npc_fastzombie		= "Zombie, Fast",
		npc_antlion			= "Antlion",
		npc_antlionguard	= "Antlion Guard",
		npc_crow			= "Crow",
		npc_pigeon			= "Pigeon",
		npc_seagull			= "Seagull",
		npc_citizen			= "Citizen",
		npc_citizen_refugee	= "Citizen, Refugee",
		npc_citizen_dt		= "Citizen, Downtrodden",
		npc_citizen_rebel	= "Rebel",
		npc_citizen_medic	= "Rebel Medic",
		npc_combine_s		= "Combine Soldier",
		npc_combine_p		= "Combine, Prison",
		npc_combine_e		= "Combine, Elite",
		npc_metropolice		= "Metrocop",
		npc_manhack			= "Manhack",
		npc_rollermine		= "Rollermine",
		npc_vortigaunt		= "Vortigaunt"
	};
	if (util.IsValidModel("models/hunter.mdl")) then
		npcspawner.npcs["npc_hunter"] = "Hunter";
	end if (util.IsValidModel("models/zombie/zombie_soldier.mdl")) then
		npcspawner.npcs["npc_zombine"] = "Zombine";
	end
end
if (file.Exists("npcspawner2/weps.txt")) then
	local data = util.KeyValuesToTable(file.Read("npcspawner2/weps.txt"));
	if (table.Count(data) > 0) then
		npcspawner.weps = data;
	end
end
if (not npcspawner.weps) then
	npcspawner.weps = {
		weapon_crowbar			= "Crowbar",
		weapon_stunstick		= "Stunstick",
		weapon_pistol			= "Pistol",
		weapon_alyxgun			= "Alyx's Gun",
		weapon_smg1				= "SMG",
		weapon_ar2				= "AR2",
		weapon_shotgun			= "Shotgun",
		weapon_annabelle		= "Anabelle",
	--	weapon_rpg				= "RPG", -- RPG doesn't work D:
		weapon_citizenpackage	= "Package",
		weapon_citizensuitcase	= "Suitcase",
		weapon_none				= "None",
		weapon_rebel			= "Random Rebel Weapon",
		weapon_combine			= "Random Combine Weapon",
		weapon_citizen			= "Random Citizen Weapon"
	};
end
if (file.Exists("npcspawner2/config.txt")) then
	local data = util.KeyValuesToTable(file.Read("npcspawner2/config.txt") or "");
	if (table.Count(data) > 0) then
		npcspawner.config = data
	end
end
if (not npcspawner.config) then
	npcspawner.config = {
		adminonly	= 0,
		callhooks	= 1,
		maxinplay	= 20,
		mindelay	= 0.1,
		debug		= 0,
	};
end
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

--[[
umsg.PoolString"NPCSpawner NPCs";
umsg.PoolString"NPCSpawner Weps";
umsg.PoolString"NPCSpawner Config";
--]]

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
