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

function ENT:SpawnFunction(ply, tr)
	if (not tr.Hit) then return end
	local ent = ents.Create("sent_spawnplatform");
	ent:SetPos(tr.HitPos + tr.HitNormal * 16);
	ent:SetPlayer(ply);
	ent:Spawn();
	ent:Activate();
	return ent;
end

--[[ The built in duplicator function messes with the platform too much ]]--
duplicator.RegisterEntityClass("sent_spawnplatform", function(ply, data)
	if (BaseClass.CanDuplicate(ply, data)) then
		return BaseClass.GenericDuplicate(ply, data);
	end
	return nil;
end, "Data");

-- Deal with old save data
function ENT:OnDuplicated(data)
	for key, value in pairs(data) do
		if (key:sub(1, 2) == "k_") then
			self:SetKeyValue(key:sub(3), value);
		end
	end
end

function ENT:OnEntityCopyTableFinish(tab)
	if (BaseClass.OnEntityCopyTableFinish) then BaseClass.OnEntityCopyTableFinish(self, tab) end;
	-- Purge all legacy cruft from the dupe
	for key in pairs(tab) do
		if (key:sub(1, 2) == "k_") then
			tab[key] = nil;
		end
	end
end
