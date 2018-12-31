--[[
	NPC Spawn Platforms V2 - lua/entities/sent_spawnplatform/init.lua
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

AddCSLuaFile("shared.lua");
include("shared.lua");

include("sv_duplication.lua")
include("sv_reliability.lua")
include("sv_spawning.lua")
include("sv_wire.lua")

DEFINE_BASECLASS(ENT.Base);

ENT.NPCs         = {};
ENT.Spawned      = 0;
ENT.LastSpawn    = 0;
ENT.LastChange   = 0;
ENT.TotalSpawned = 0;

local colour_on = Color(0, 255, 0)
local colour_off = Color(255, 0, 0)
local colour_flipped = Color(0, 255, 255)

numpad.Register("NPCSpawnerOn", function(ply, ent)
	npcspawner.debug("Numpad on called for", ent, "by", ply);
	if (IsValid(ent)) then
		ent:TurnOn();
	else
		npcspawner.debug("Invalid entity provided?!");
	end
end);

numpad.Register("NPCSpawnerOff", function(ply, ent)
	npcspawner.debug("Numpad off called for", ent, "by", ply);
	if (IsValid(ent)) then
		ent:TurnOff();
	else
		npcspawner.debug("Invalid entity provided?!");
	end
end);

function ENT:Initialize()
	npcspawner.debug2(self, "now exists!");
	-- Ensure the right model etc is set
	self:OnActiveChange(nil, nil, self:IsActive());
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid   (SOLID_VPHYSICS);
	local phys = self:GetPhysicsObject();
	if (not IsValid(phys)) then
		ErrorNoHalt("No physics object for ", tostring(self), " using model ", self:GetModel(), "?\n");
	elseif (self:GetFrozen()) then
		phys:EnableMotion(false);
	else
		phys:Wake();
	end

	self:ResetLastSpawn();
	self.Spawned = 0;
	self.NPCs    = {};
	self:UpdateLabel();

	self:SetupWire();
end

function ENT:CanSpawnNPC()
	return (
		self:IsActive()
		and self.Spawned < self:GetMaxNPCs()
		and (self.LastSpawn + self:GetSpawnDelay()) <= CurTime()
	)
end

function ENT:OrentationThink()
	if (not self:IsActive()) then
		return true;
	end

	if (not self:CheckOrientation()) then
		if (not self:IsFlipped()) then
			self:SetFlipped(true);
			self:DoColour(colour_flipped)
		end

		return false;
	elseif (self:IsFlipped()) then
		self:SetFlipped(false);
		self:DoColour(colour_on)
	end

	return true;
end

function ENT:Think()
	if (BaseClass.Think) then BaseClass.Think(self); end

	if (not self:OrentationThink()) then
		return;
	end

	if (self:CanSpawnNPC()) then
		self:SpawnOne();
	end
end

function ENT:NPCKilled(npc)
	npcspawner.debug2("NPC Killed:", npc);
	self.NPCs[npc] = nil;
	-- Make the delay apply after the nth NPC dies.
	if (not self:GetLegacySpawnMode() and self.Spawned >= self:GetMaxNPCs()) then
		self.LastSpawn = CurTime();
	end
	self.Spawned = self.Spawned - 1;
	-- "This should never happen"
	if (self.Spawned < 0) then
		self.Spawned = 0
	end
	self:TriggerOutput("OnNPCKilled", self);
	self:TriggerWireOutput("ActiveNPCs", self.Spawned);
end

function ENT:Use(activator, caller)
	if (not self:GetCanToggle() or self.LastChange + 1 > CurTime()) then
		return;
	end
	npcspawner.debug(self, "has been used by", activator, caller)
	self:Toggle();
end

function ENT:Toggle()
	if (self:IsActive()) then
		npcspawner.debug(self, "has toggled from on to off.");
		self:TurnOff();
	else
		npcspawner.debug(self, "has toggled from off to on.");
		self:TurnOn();
	end
end

function ENT:TurnOn()
	self:SetActive(true);
	self.TotalSpawned = 0;
	self:SetSpawnDelay(self:GetStartDelay());
	self:TriggerWireOutput("TotalNPCsSpawned", self.TotalSpawned);
end

function ENT:TurnOff()
	self:SetActive(false);
end

function ENT:DoColour(new)
	new.a = self:GetColor().a
	self:SetColor(new)
end

local model_active = Model("models/props_c17/streetsign004e.mdl");
local model_inactive = Model("models/props_c17/streetsign004f.mdl");
function ENT:OnActiveChange(_, _, active)
	npcspawner.debug2(self, "is set to active state:", active);
	local c = self:GetColor();
	local a = c.a;
	if (active) then
		self:SetModel(model_active);
		self.LastSpawn = CurTime();
		if (self:IsFlipped()) then
			self:DoColour(colour_flipped)
		else
			self:DoColour(colour_on)
		end
	else
		self:SetModel(model_inactive);
		self:DoColour(colour_off)
	end
	self:TriggerWireOutput("IsOn", active and 1 or 0);
	self.LastChange = CurTime();
end

function ENT:RemoveNPCs()
	npcspawner.debug(self, "is deleting its NPCs.");
	for ent in pairs(self.NPCs) do
		if IsValid(ent) then
			ent:Remove();
		end
	end
	self.NPCs = {};
	self.Spawned = 0;
	self:TriggerWireOutput("ActiveNPCs", self.Spawned);
end

--[[ Hammer I/O ]]--
function ENT:AcceptInput(name, activator, called, value)
	if (BaseClass.AcceptInput and BaseClass.AcceptInput(self, name, activator, called, value)) then
		return true;
	end

	npcspawner.debug2(self, "has just had their", name, "triggered by", tostring(called), "which was caused by", tostring(activator), "and was passed", value);

	if (name == "TurnOn") then
		self:TurnOn();
		return true;
	elseif (name == "TurnOff") then
		self:TurnOff();
		return true;
	elseif (name == "RemoveNPCs") then
		self:RemoveNPCs();
		return true;
	elseif (name == "SpawnOne") then
		self:SpawnOne();
		return true;
	end

    return false;
end
