--[[
	NPC Spawn Platforms V2 - lua/entities/sent_spawnplatform/sv_duplication.lua
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

-- The built in duplicator function messes with the platform too much
duplicator.RegisterEntityClass("sent_spawnplatform", function(ply, data)
	if (npcspawner.config.adminonly == 1 and IsValid(ply) and not ply:IsAdmin()) then
		npcspawner.debug(ply, "tried to duplicate a platform in admin mode but isn't an admin!");
		return nil;
	end

	if (BaseClass.CanDuplicate(ply, data)) then
		return BaseClass.GenericDuplicate(ply, data);
	end

	return nil;
end, "Data");

ENT.__MODIFIER_ID = "NPC Spawn Platforms Spawner"
-- So we can attempt to re-attribute NPCs to their platforms on save/restore
duplicator.RegisterEntityModifier(ENT.__MODIFIER_ID, function(ply, ent, data)
	-- This is blank because we don't need to modify the entity at all
end);

-- Deal with old save data
function ENT:OnDuplicated(data)
	if (BaseClass.OnDuplicated) then BaseClass.OnDuplicated(self, data) end;

	npcspawner.debug2(self, "has been duplicated!");

	-- Since we disable table.merge above, we need to hang on to this
	self._saveRestore = data._saveRestore

	for key, value in pairs(data) do
		if (key:sub(1, 2) == "k_") then
			self:SetKeyValue(key:sub(3), value);
		end
	end
end

function ENT:PostEntityPaste(ply, _, entList)
	if (BaseClass.PostEntityPaste) then BaseClass.PostEntityPaste(self, ply, _, entList) end;

	if (not self._saveRestore) then
		return;
	end
	npcspawner.debug2(self, "found save data, attempting to restore");

	local oldID = self._saveRestore.creationID;

	local lastNPC, lastID = nil, -1;

	npcspawner.debug2("expecting to find", self._saveRestore.numSpawned, "NPCs in the entlist");
	for _, ent in pairs(entList) do
		-- Because not all entitymods may have been applied by this point, we need to check them manually
		local tab = ent.EntityMods and ent.EntityMods[self.__MODIFIER_ID];
		if (tab and tab.id == oldID) then
			npcspawner.debug2("adding", ent, "as a child");
			if (tab.myid > lastID) then
				lastNPC = ent;
				lastID = tab.myid;
			end

			self:ConfigureNPCOwnership(ent)
			self.Spawned = self.Spawned + 1;
		end
	end

	-- Check to see if we didn't manage to save some of our NPCs
	local missing = self._saveRestore.numSpawned - self.Spawned;
	if (missing > 0 and npcspawner.config.rehydrate == 1) then
		npcspawner.debug(self, "is spawning", missing, "NPCs to make up its deficit")
		for i = 1, missing do
			local n = self:SpawnOne();
			if not n then
				-- Oops
				npcspawner.debug("Aborting NPC rehydration!")
				break;
			end
		end
	else
		self:TriggerWireOutput("ActiveNPCs", self.Spawned);
		if (lastNPC) then
			self:TriggerWireOutput("LastNPCSpawned", lastNPC);
		end
	end
	self.TotalSpawned = self._saveRestore.total;
	self:TriggerWireOutput("TotalNPCsSpawned", self.TotalSpawned);

	-- Restore LastSpawn so saves are consistent
	npcspawner.debug2("Setting LastSpawn to be", self._saveRestore.lastSpawn, "seconds in the past");
	self.LastSpawn = self._saveRestore.lastSpawn + CurTime();

	self._saveRestore = nil;
end

function ENT:OnEntityCopyTableFinish(tab)
	if (BaseClass.OnEntityCopyTableFinish) then BaseClass.OnEntityCopyTableFinish(self, tab) end;
	-- Purge all legacy cruft from the dupe
	for key in pairs(tab) do
		if (key:sub(1, 2) == "k_") then
			tab[key] = nil;
		end
	end
	-- For save/restore
	tab._saveRestore = {
		creationID = self:GetCreationID(),
		numSpawned = self.Spawned,
		total = self.TotalSpawned,
		lastSpawn = self.LastSpawn - CurTime(),
	};
end
