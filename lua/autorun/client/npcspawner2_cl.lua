--[[
	NPC Spawn Platforms V2.1
	~ Lexi ~
--]]
--[[ Defaults (in case the server is uncommunicative.) ]]--
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
npcspawner.weps = {
	weapon_crowbar			= "Crowbar",
	weapon_stunstick		= "Stunstick",
	weapon_pistol			= "Pistol",
	weapon_alyxgun			= "Alyx's Gun",
	weapon_smg1				= "SMG",
	weapon_ar2				= "AR2",
	weapon_shotgun			= "Shotgun",
	weapon_annabelle		= "Anabelle",
	weapon_citizenpackage	= "Package",
	weapon_citizensuitcase	= "Suitcase",
	weapon_none				= "None",
	weapon_rebel			= "Random Rebel Weapon",
	weapon_combine			= "Random Combine Weapon",
	weapon_citizen			= "Random Citizen Weapon"
};
npcspawner.config = {
	adminonly	= 0,
	callhooks	= 1,
	maxinplay	= 20,
	mindelay	= 0.1,
	debug		= 0,
};
local cvarstr = "npcspawner_config_";
local function callback(cvar, old, new)
	cvar = cvar:gsub(cvarstr, "");
--	print(cvar, old, new);
	new = tonumber(new) or npcspawner.config[cvar];
	if (npcspawner.config[cvar] ~= new) then
--		print("chonged");
		npcspawner.config[cvar] = new;
		if (LocalPlayer():IsAdmin()) then
--			print("sending");
			RunConsoleCommand("npcspawner_config", cvar, new);
		end
	end
end
for k, v in pairs(npcspawner.config) do
	CreateConVar(cvarstr .. k, tostring(v));
	cvars.AddChangeCallback(cvarstr .. k, callback);
end
usermessage.Hook("npcspawner_config", function(msg)
	local cvar, value = msg:ReadString(), msg:ReadFloat()
	npcspawner.config[cvar] = value;
	RunConsoleCommand(cvarstr .. cvar, tostring(value));
end);
npcspawner.recieve("NPCSpawner NPCs", function(data)
	npcspawner.npcs = data;
	npcspawner.debug("Just got new npc vars.");
end);
npcspawner.recieve("NPCSpawner Weps", function(data)
	npcspawner.weps = data;
	npcspawner.debug("Just got new weapon vars.");
end);
npcspawner.recieve("NPCSpawner Config", function(data)
	npcspawner.config = data;
	npcspawner.debug("Just got new config vars.");
	for k, v in pairs(npcspawner.config) do
		RunConsoleCommand(cvarstr .. k, tostring(v))
	end
end);
-----------------------------------
-- Lexical Patented Corpse Eater --
-----------------------------------
CreateConVar("cleanupcorpses", 1);
timer.Create("Dead Body Deleter", 60, 0, function()
	if (GetConVarNumber("cleanupcorpses") < 1) then return; end
	for _, ent in pairs(ents.FindByClass("class C_ClientRagdoll")) do
		ent:Remove()
	end
end);
language.Add ("Tool_npc_spawnplatform_name", "NPC Spawn Platforms MK2");
language.Add ("Tool_npc_spawnplatform_desc", "Create a platform that will constantly make NPCs.");
language.Add ("Tool_npc_spawnplatform_0", "Left-click: Spawn/Update Platform.  Right-click: Copy Platform Data.");
--do return; end
local function OnPopulateToolPanel(panel)
	panel:AddControl("Label", {
		Text = "Cleanup Corpses: This will clean up all the clientside corpses every minute if enabled."
	});
	panel:AddControl("CheckBox", {
		Label = "Cleanup Corpses",
		Command = "cleanupcorpses",
	})
	if (not LocalPlayer():IsAdmin()) then
		return;
	end
	panel:AddControl("Label", {
		Text = "Admins only: This will stop non-admins from being able to use the spawnplatforms STool."
	});
	panel:AddControl("CheckBox", {
		Label = "Admins Only",
		Command = "npcspawner_config_adminonly",
	})
	panel:AddControl("Label", {
		Text = "Call Hooks: This will cause the platform to call all the sandbox hooks, as if the player was using the Spawn Menu to make NPCs."
	});
	panel:AddControl("CheckBox", {
		Label = "Call Hooks",
		Command = "npcspawner_config_callhooks",
	})
	panel:AddControl("Label", {
		Text = "Max In Play: The maximum number of NPCs a single spawnplatform can have out at once."
	});
	panel:AddControl("Slider", {
		Label = "Max In Play",
		Command = "npcspawner_config_maxinplay",
		Type = "Float",
		Min = "1",
		Max = "50",
	})
	panel:AddControl("Label", {
		Text = "Minimum Delay: The minimum delay between each npc spawn."
	});
	panel:AddControl("Slider", {
		Label = "Max In Play",
		Command = "npcspawner_config_mindelay",
		Type = "Float",
		Min = "0.1",
		Max = "10",
	})
	--[[
	panel:AddControl("Label", {
		Text = "Debug Mode: Enable printing debug info if the developer convar is greater than 0."
	});
	panel:AddControl("CheckBox", {
		Label = "Debug Mode",
		Command = "npcspawner_config_debug",
	})
	--]]
end
hook.Add("PopulateToolMenu", "NPCSpawner Options", function()
	spawnmenu.AddToolMenuOption("Options", "Addons", "NPC Spawn Platforms", "NPC Spawn Platforms", "", "", OnPopulateToolPanel)
end)
