--[[
	NPC Spawn Platforms V2
	Copyright (c) 2011-2016 Lex Robinson
	This code is freely available under the MIT License
--]]

ENT.Type           = "anim";
ENT.Base           = "base_gmodentity";
ENT.PrintName      = "NPC Spawn Platform";
ENT.Author         = "Lexi/Devenger";
ENT.Purpose        = "Spawn a constant(ish) stream of NPCs";
ENT.Spawnable      = false;
ENT.AdminSpawnable = true;

print("Hello from the Spawn Platform!");

local function convert( text )
	-- return npcspawner.npcs[text] or npcspawner.weps[text] or text;
	-- TODO: Look in the "NPC" and "NPCUsableWeapons" lists for the names
	return text;
end

function ENT:UpdateLabel()
	self:SetOverlayText(
		"NPC: "       .. convert(self:GetNPC()      )  ..
		"\nWeapon: "  .. convert(self:GetNPCWeapon())  ..
		"\nDelay: "   ..         self:GetSpawnDelay()  ..
		"\nMaximum: " ..         self:GetMaximumNPCs()
	);
end

function ENT:GetNPCName()
	return convert(self:GetNWString("npc"));
end

function ENT:IsActive()
	return self:GetActive();
end

local function StartDelayCustomSet(self, value)
	value = math.max(value, npcspawner.config.mindelay);
	self:SetStartDelay(value);
end

ENT._NWVars = {
	{
		Type = "Bool";
		Name = "Active";
		LegacyName = "active";
		Default = false;
	},

	{
		Type = "String";
		Name = "NPC";
		LegacyName = "npc";
		Default = "npc_combine_s";
	},
	{
		Type = "String";
		Name = "NPCWeapon";
		LegacyName = "weapon";
		Default = "weapon_smg1";
	},
	{
		Type = "Float";
		Name = "NPCHealthMultiplier";
		LegacyName = "healthmul";
		Default = 1;
	},
	{
		Type = "Int";
		Name = "NPCSkillLevel";
		LegacyName = "skill";
		Default = WEAPON_PROFICIENCY_AVERAGE;
	},

	{
		Type = "Int";
		Name = "MaxNPCs";
		LegacyName = "maximum";
		Default = 5;
	},
	{
		Type = "Int";
		Name = "MaxNPCsTotal";
		LegacyName = "totallimit";
		Default = 0;
	},

	{
		Type = "Int";
		Name = "OnKey";
		LegacyName = "OnKey";
	},
	{
		Type = "Int";
		Name = "OffKey";
		LegacyName = "offkey";
	},

	{
		Type = "Bool";
		Name = "CustomSquad";
		LegacyName = "customsquads";
		Default = false;
	},
	{
		Type = "Int";
		Name = "SquadOverride";
		LegacyName = "squadoverride";
		Default = 0;
	},

	{
		Type = "Float";
		Name = "StartDelay";
		LegacyName = "delay";
		Special = {
			Set = StartDelayCustomSet
		};
		Default = 5;
	},
	{
		Type = "Float";
		Name = "DelayDecrease";
		LegacyName = "decrease";
		Default = 0;
	},
	{
		Type = "Float";
		Name = "SpawnDelay";
	},

	{
		Type = "Bool";
		Name = "CanToggle";
		LegacyName = "toggleable";
		Default = true;
	},
	{
		Type = "Bool";
		Name = "AutoRemove";
		LegacyName = "autoremove";
		Default = true;
	},

	{
		Type = "Int";
		Name = "SpawnHeight";
		LegacyName = "spawnheight";
		Default = 16;
	},
	{
		Type = "Int";
		Name = "SpawnRadius";
		LegacyName = "spawnradius";
		Default = 16;
	},
	{
		Type = "Bool";
		Name = "NoCollideNPCs";
		LegacyName = "nocollide";
		Default = true;
	},
	{
		Type = "Bool";
		Name = "Frozen";
		LegacyName = "frozen";
		Default = true;
	},

	{
		Type = "Entity";
		Name = "Player";
		Default = NULL;
	},
	{
		Type = "Int";
		Name = "PlayerID";
		LegacyName = "ply";
	},
}

function ENT:SetupDataTables()
	-- In order not to break existing compatability, make sure all
	--  keys are still available under their old names.
	local argh = {};
	local function legacyShite(ent, key, old, new)
		local what = argh[key];
		if (what) then
			ent["k_" .. what.LegacyName] = tostring(new);
		end
	end

	local NWCounts = {};

	for _, nwvar in pairs(self._NWVars) do
		argh[nwvar.Name] = nwvar;
		local id = NWCounts[nwvar.Type] or 0;
		local special = nwvar.Special or {};
		special.KeyName = nwvar.LegacyName;
		self:NetworkVar(nwvar.Type, id, nwvar.Name, special);
		if (nwvar.LegacyName) then
			self:NetworkVarNotify(nwvar.Name, legacyShite);
		end
		if (nwvar.Default ~= nil) then
			self["Set" .. nwvar.Name](self, nwvar.Default);
		end
		NWCounts[nwvar.Type] = id + 1;
	end

	if (SERVER) then
		self:RegisterListeners();
	end
end
