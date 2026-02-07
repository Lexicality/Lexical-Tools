--[[
	NPC Spawn Platforms - lua/entities/sent_spawnplatform/shared.lua
    Copyright 2009-2020 Lex Robinson

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
]]
ENT.Type = "anim"
ENT.PrintName = "NPC Spawn Platform"
ENT.WireDebugName = "Spawn Platform"
ENT.Author = "Lexi/Devenger"
ENT.Purpose = "Spawn a constant(ish) stream of NPCs"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.CountKey = "Spawnplatforms"

DEFINE_BASECLASS("base_lexentity")

local function StartDelayCustomSet(self, value)
	value = math.max(value, npcspawner.config.mindelay)
	self:SetStartDelay(value)
end
local function MaxNPCsCustomSet(self, value)
	value = math.min(value, npcspawner.config.maxinplay)
	self:SetMaxNPCs(value)
end

ENT._NWVars = {
	{Type = "Bool", Name = "Active", KeyName = "active", Default = false},
	{Type = "Bool", Name = "Flipped", Default = false},

	{Type = "String", Name = "NPC", KeyName = "npc", Default = "npc_combine_s"},
	{
		Type = "String",
		Name = "NPCWeapon",
		KeyName = "weapon",
		Default = "weapon_smg1",
	},
	{
		Type = "Float",
		Name = "NPCHealthMultiplier",
		KeyName = "healthmul",
		Default = 1,
	},
	{
		Type = "Int",
		Name = "NPCSkillLevel",
		KeyName = "skill",
		Default = WEAPON_PROFICIENCY_AVERAGE,
	},

	{
		Type = "Int",
		Name = "MaxNPCs",
		KeyName = "maximum",
		Special = {Set = MaxNPCsCustomSet},
		Default = 5,
	},
	{Type = "Int", Name = "MaxNPCsTotal", KeyName = "totallimit", Default = 0},

	{Type = "Int", Name = "OnKey", KeyName = "OnKey"},
	{Type = "Int", Name = "OffKey", KeyName = "offkey"},

	{
		Type = "Bool",
		Name = "CustomSquad",
		KeyName = "customsquads",
		Default = false,
	},
	{Type = "Int", Name = "SquadOverride", KeyName = "squadoverride", Default = 0},

	{
		Type = "Float",
		Name = "StartDelay",
		KeyName = "delay",
		Special = {Set = StartDelayCustomSet},
		Default = 5,
	},
	{Type = "Float", Name = "DelayDecrease", KeyName = "decrease", Default = 0},
	{Type = "Float", Name = "SpawnDelay"},
	{
		Type = "Bool",
		Name = "LegacySpawnMode",
		LegacyName = "oldspawning",
		Default = false,
	},

	{Type = "Bool", Name = "CanToggle", KeyName = "toggleable", Default = true},
	{Type = "Bool", Name = "AutoRemove", KeyName = "autoremove", Default = true},

	{Type = "Int", Name = "SpawnHeight", KeyName = "spawnheight", Default = 16},
	{Type = "Int", Name = "SpawnRadius", KeyName = "spawnradius", Default = 16},
	{Type = "Bool", Name = "NoCollideNPCs", KeyName = "nocollide", Default = true},
	{Type = "Bool", Name = "Frozen", KeyName = "frozen", Default = true},
	{Type = "Int", Name = "RPValue", KeyName = "killvalue", Default = -1},
}

function ENT:SetupDataTables()
	if (BaseClass.SetupDataTables) then
		BaseClass.SetupDataTables(self)
	end

	-- In order not to break existing compatability, make sure all
	--  keys are still available under their old names.
	local legacy = {}
	local function onDataChanged(ent, key, old, new)
		local data = legacy[key]
		if (data) then
			ent["k_" .. data.KeyName] = tostring(new)
		end
	end

	for _, nwvar in pairs(self._NWVars) do
		if (nwvar.KeyName) then
			legacy[nwvar.Name] = nwvar
			self:NetworkVarNotify(nwvar.Name, onDataChanged)
			onDataChanged(self, nwvar.Name, nil, self["Get" .. nwvar.Name](self))
		end
	end
end

function ENT:GetPlayerID()
	-- NOTE: This function used to work on the client, but now doesn't.
	-- If you rely on this feature, please either stop relying on it or add an
	--  issue on Github
	return self.k_ply
end
