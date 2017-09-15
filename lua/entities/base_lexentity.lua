--[[
	Universal Entity Base - lua/entities/base_lexentity.lua
    Copyright 2016-2017 Lex Robinson

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

AddCSLuaFile();

ENT.Type      = "anim";
ENT.PrintName = "Lex's Base Entity";
ENT.Author    = "Lex Robinson";
ENT.Contact   = "lexi@lexi.org.uk";
ENT.Purpose   = "Abstracting away annoying features";
ENT.Spawnable = false;

local BaseClass;
if (WireLib) then
    BaseClass = "base_wire_entity"
elseif (engine.ActiveGamemode() == "sandbox") then
    BaseClass = "base_gmodentity"
else
	BaseClass = "base_anim";
end
DEFINE_BASECLASS(BaseClass);

-- Stub for non-sandbox gamemodes
function ENT:SetOverlayText(...)
	if (BaseClass.SetOverlayText) then
		BaseClass.SetOverlayText(self, ...);
	end
end

function ENT:SetupDataTables()
	if (BaseClass.SetupDataTables) then BaseClass.SetupDataTables(self); end

	if (not self._NWVars) then
		return;
	end

	local NWCounts = {};

	for _, nwvar in pairs(self._NWVars) do
		local id = NWCounts[nwvar.Type] or 0;
		local special = nwvar.Special or {};
		special.KeyName = nwvar.KeyName;
		special.Edit = nwvar.Edit;
		self:NetworkVar(nwvar.Type, id, nwvar.Name, special);

		if (nwvar.Default ~= nil) then
			self["Set" .. nwvar.Name](self, nwvar.Default);
		end
		NWCounts[nwvar.Type] = id + 1;
	end

	if (SERVER and self.RegisterListeners) then
		self:RegisterListeners();
	end
end

if (CLIENT) then
	return;
end

function ENT:KeyValue(key, value)
	if (BaseClass.KeyValue) then BaseClass.KeyValue(self, key, value); end

	if (self:SetNetworkKeyValue(key, value)) then
		-- NWVars
		return;
	elseif (key:sub(1, 2) == "On") then
		-- Hammer IO
		self:StoreOutput(key, value);
		return;
	end
end

local function splode(data)
	local a, b = data:find(" ", 1, true);
	return data:sub(1, a), data:sub(b);
end

function ENT:AcceptInput(name, activator, called, value)
	if (BaseClass.AcceptInput) then BaseClass.AcceptInput(self, name, activator, called, value); end

	if (name == "AddOutput") then
		-- This is literally KeyValue but as an input and with ,s as :s.
		name, value = splode(value);

		value = value:gsub(":", ",");
		self:KeyValue(name, value);
	end
end

-- Wire nonsense
function ENT:CreateWireInputs(tab)
	if (not WireLib) then
		return;
	end
	local names, types, descs = {}, {}, nil;
	for i, input in pairs(tab) do
		names[i] = input.Name;
		types[i] = (input.Type or "Normal"):upper();
		-- Wire displays descriptions horribly
		-- descs[i] = input.Desc;
	end
	WireLib.CreateSpecialInputs(self, names, types, descs);
end

function ENT:CreateWireOutputs(tab)
	if (not WireLib) then
		return;
	end

	local names, types, descs = {}, {}, nil;
	for i, output in pairs(tab) do
		names[i] = output.Name;
		types[i] = (output.Type or "Normal"):upper();
		-- Wire displays descriptions horribly
		-- descs[i] = output.Desc;
	end
	WireLib.CreateSpecialOutputs(self, names, types, descs);
end

function ENT:TriggerWireOutput(name, value)
	if (WireLib) then
		WireLib.TriggerOutput(self, name, value);
	end
end

-- 'Class' function
function ENT.CanDuplicate(ply, data)
	-- A mixture of duplicator copy/paste & sandbox boilerplate
	if (not duplicator.IsAllowed(data.Class)) then
		return false;
	elseif (not IsValid(ply)) then
		return true;
	end

	if (not ply:IsAdmin()) then
		if (not scripted_ents.GetMember(data.Class, "Spawnable")) then
			return false;
		elseif (scripted_ents.GetMember(data.Class, "AdminOnly")) then
			return false;
		end
	end

	if (ply.CheckLimit and not ply:CheckLimit(data.Class)) then
		return false;
	end

	return true;
end

-- This is just like duplicator.GenericDuplicatorFunction but it doesn't merge the data table with the entity
-- It also handles sandbox limits
function ENT.GenericDuplicate(ply, data)
	local ent = ents.Create(data.Class);
	if (not IsValid(ent)) then
		return;
	end

	duplicator.DoGeneric(ent, data);

	ent:Spawn();
	ent:Activate();

	duplicator.DoGenericPhysics(ent, ply, data);

	if (IsValid(ply)) then
		if (ent.SetPlayer) then ent:SetPlayer(ply) end
		if (ply.AddCount) then ply:AddCount(data.Class, ent) end
		if (ply.AddCleanup) then ply:AddCleanup(data.Class, ent) end
	end
	return ent;
end
