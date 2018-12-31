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

function ENT:ResetLastSpawn()
	self.LastSpawn = CurTime();
end

local function labelr(self)
	timer.Simple(0, function() self:UpdateLabel() end);
end

function ENT:RegisterListeners()
	self:NetworkVarNotify("Active", self.OnActiveChange);
	self:NetworkVarNotify("StartDelay", self.OnStartDelayChange);
	self:NetworkVarNotify("PlayerID", self.OnPlayerIDChange);
	self:NetworkVarNotify("Player", self.OnPlayerChange);
	self:NetworkVarNotify("Frozen", self.OnFrozenStateChange);
	self:NetworkVarNotify("OnKey", function(self, _, _, onKey)
		self:RebindNumpads(self:GetPlayer(), onKey, self:GetOffKey());
	end)
	self:NetworkVarNotify("OffKey", function(self, _, _, offKey)
		self:RebindNumpads(self:GetPlayer(), self:GetOnKey(), offKey);
	end)
	self:NetworkVarNotify("NPC", labelr);
	self:NetworkVarNotify("NPCWeapon", labelr);
	self:NetworkVarNotify("SpawnDelay", labelr);
	self:NetworkVarNotify("MaxNPCs", labelr);
	self:NetworkVarNotify("Flipped", labelr);
	self:NetworkVarNotify("Active", labelr);
end

function ENT:OnStartDelayChange(_, _, delay)
	self:SetSpawnDelay(delay);
	self:ResetLastSpawn();
end

-- Recursive functions are fun
local _isInPlayerSet = false;

function ENT:OnPlayerIDChange(_, _, plyID)
	local ply = player.GetByID(plyID);
	_isInPlayerSet = true;
	self:SetPlayer(ply);
	_isInPlayerSet = false;
end

function ENT:OnPlayerChange(_, oldPly, ply)
	if (not _isInPlayerSet) then
		-- Keep this dumb shit synchronised
		local plyIndex = 0;
		if (IsValid(ply)) then
			plyIndex = ply:EntIndex();
		end
		self:SetPlayerID(plyIndex);
	end
	if (ply ~= oldPly) then
		self:RebindNumpads(ply, self:GetOnKey(), self:GetOffKey());
	end
end

function ENT:OnFrozenStateChange(_, _, freeze)
	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:EnableMotion(not freeze);
		if (not freeze) then
			phys:Wake();
		end
	end
end

ENT._prevOnKeypad = false;
ENT._prevOffKeypad = false;
function ENT:RebindNumpads(ply, keyOn, keyOff)
	numpad.Remove(self._prevOffKeypad);
	numpad.Remove(self._prevOnKeypad);
	self._prevOnKeypad = false;
	self._prevOffKeypad = false;

	if (not IsValid(ply)) then
		return;
	end

	if (keyOn) then
		self._prevOnKeypad = numpad.OnDown(ply, keyOn, "NPCSpawnerOn", self);
	end
	if (keyOff) then
		self._prevOffKeypad = numpad.OnDown(ply, keyOff, "NPCSpawnerOff", self);
	end
end

function ENT:OnRemove()
	if (BaseClass.OnRemove) then BaseClass.OnRemove(self); end
	npcspawner.debug(self, "has been removed.");
	if (self:GetAutoRemove()) then
		self:RemoveNPCs();
	end
	self:RebindNumpads(NULL, false, false);
end
