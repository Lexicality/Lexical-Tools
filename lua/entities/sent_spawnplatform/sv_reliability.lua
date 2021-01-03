--[[
	NPC Spawn Platforms - lua/entities/sent_spawnplatform/sv_wire.lua
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
]] --
DEFINE_BASECLASS(ENT.Base)

function ENT:ResetLastSpawn()
	self.LastSpawn = CurTime()
end

function ENT:RegisterListeners()
	self:NetworkVarNotify("Active", self.OnActiveChange)
	self:NetworkVarNotify("StartDelay", self.OnStartDelayChange)
	self:NetworkVarNotify("Frozen", self.OnFrozenStateChange)
	self:NetworkVarNotify("OnKey", function(self, _, _, onKey)
		self:RebindNumpads(self:GetPlayer(), onKey, self:GetOffKey())
	end)
	self:NetworkVarNotify("OffKey", function(self, _, _, offKey)
		self:RebindNumpads(self:GetPlayer(), self:GetOnKey(), offKey)
	end)
end

function ENT:OnStartDelayChange(_, _, delay)
	self:SetSpawnDelay(delay)
	self:ResetLastSpawn()
end

function ENT:SetPlayerID(plyID)
	-- NOTE: This function used to be shared, even though calling it on the
	--  client was incorrect and would break things. Also you should never have
	--  been calling it in the first place
	-- If you rely on this feature, please either stop relying on it or add an
	--  issue on Github
	self:SetKeyValue("ply", plyID)
end

function ENT:SetPlayer(ply)
	local oldPly = self:GetPlayer()

	BaseClass.SetPlayer(self, ply)

	if (IsValid(ply)) then
		-- NOTE: This is not actually the correct ID
		-- If you rely on this feature, please either stop relying on it or
		--  add an issue on Github
		self.k_ply = ply:EntIndex()
	end

	if (ply ~= oldPly) then
		self:RebindNumpads(ply, self:GetOnKey(), self:GetOffKey())
	end
end

function ENT:KeyValue(key, value)
	if (BaseClass.KeyValue) then
		BaseClass.KeyValue(self, key, value)
	end

	if (key == "ply") then
		-- NOTE: This function doesn't actually use a useful or easy to obtain ID.
		-- If you rely on this feature, please either stop relying on it or
		--  add an issue on Github
		local ply = player.GetByID(value)
		self:SetPlayer(ply)
	end
end

function ENT:OnFrozenStateChange(_, _, freeze)
	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:EnableMotion(not freeze)
		if (not freeze) then
			phys:Wake()
		end
	end
end

function ENT:RebindNumpads(ply, keyOn, keyOff)
	numpad.Remove(self._prevOffKeypad)
	numpad.Remove(self._prevOnKeypad)
	self._prevOnKeypad = false
	self._prevOffKeypad = false

	if (not IsValid(ply)) then
		return
	end

	if (keyOn) then
		self._prevOnKeypad = numpad.OnDown(ply, keyOn, "NPCSpawnerOn", self)
	end
	if (keyOff) then
		self._prevOffKeypad = numpad.OnDown(ply, keyOff, "NPCSpawnerOff", self)
	end
end

function ENT:OnRemove()
	if (BaseClass.OnRemove) then
		BaseClass.OnRemove(self)
	end
	npcspawner.debug(self, "has been removed.")
	if (self:GetAutoRemove()) then
		self:RemoveNPCs()
	end
	self:RebindNumpads(NULL, false, false)
end
