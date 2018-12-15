--[[
	NPC Spawn Platforms V2 - lua/entities/sent_spawnplatform/sv_wire.lua
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

DEFINE_BASECLASS(ENT.Base);

function ENT:SetupWire()
	self:CreateWireInputs({
		{
			Name = "SetActive";
			Desc = "Set the active state of the platform";
		};
		{
			Name = "SpawnOne";
			Desc = "Force the spawning of a NPC";
		};
		{
			Name = "NPCClass";
			Desc = "Set the class of NPC to spawn";
			Type = "STRING";
		};
		{
			Name = "MaxActiveNPCs";
			Desc = "Set the max number of active NPCs";
		};
		{
			Name = "SpawnDelay";
			Desc = "Set the spawn delay";
		};
		{
			Name = "Weapon";
			Desc = "Set what weapon to give the NPCs";
			Type = "STRING";
		};
		{
			Name = "HealthMultiplier";
			Desc = "Set the health multiplier for the NPCs";
		};
		{
			Name = "MaxSpawnedNPCs";
			Desc = "Set the total number of NPCs to spawn before turning off";
		};
		{
			Name = "DelayDecreaseAmount";
			Desc = "Set how much to decrease the delay by every MaxActiveNPCs spawned";
		};
		{
			Name = "RemoveNPCs";
			Desc = "Delete all NPCs currently spawned.";
		};
	});
	self:CreateWireOutputs({
		{
			Name = "IsOn";
			Desc = "Is the platform on?";
		};
		{
			Name = "ActiveNPCs";
			Desc = "The number of currently active NPCs";
		};
		{
			Name = "TotalNPCsSpawned";
			Desc = "The total number of NPCs spawned this active session";
		};
		{
			Name = "LastNPCSpawned";
			Desc = "The last NPC the platform spawned";
			Type = "ENTITY";
		};
		{
			Name = "OnNPCSpawned";
			Desc = "Triggered every time a NPC is spawned.";
		};
	});
end

function ENT:TriggerInput(name, val)
	if (BaseClass.TriggerInput) then BaseClass.TriggerInput(self, name, val); end

	npcspawner.debug2(self, "has recieved wire input with name", name, "and value", val);
	if (name == "SetActive") then
		if (val == 0) then
			self:TurnOff();
		else
			self:TurnOn();
		end
	elseif (name == "RemoveNPCs") then
		if (val ~= 0) then
			self:RemoveNPCs();
		end
	elseif (name == "SpawnOne") then
		if (val ~= 0) then
			self:SpawnOne();
		end
	elseif (name == "NPCClass") then
		self:KeyValue("npc", val);
	elseif (name == "MaxActiveNPCs") then
		self:KeyValue("maximum", val);
	elseif (name == "SpawnDelay") then
		self:KeyValue("delay", val);
	elseif (name == "Weapon") then
		self:KeyValue("weapon", val);
	elseif (name == "HealthMultiplier") then
		self:KeyValue("healthmul", val);
	elseif (name == "MaxSpawnedNPCs") then
		self:KeyValue("totallimit", val);
	elseif (name == "DelayDecreaseAmount") then
		self:KeyValue("decrease", val);
	end
end

