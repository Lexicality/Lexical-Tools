--[[
	Universal Entity Base - lua/entities/base_lexentity.lua
    Copyright 2016-2018 Lex Robinson

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
elseif (gmod.GetGamemode().IsSandboxDerived) then
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

		if (nwvar.Type == "Bool") then
			-- Booleans look better when you can call IsSecure rather than GetSecure etc.
			self["Is" .. nwvar.Name] = function(self)
				return self.dt[nwvar.Name];
			end
		end

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
		return;
	elseif (self:AddOutputFromKeyValue(key, value)) then
		return;
	end
end

function ENT:AddOutputFromKeyValue(key, value)
	if (key:sub( 1, 2 ) == "On") then
		self:StoreOutput(key, value);
		return true;
	end

	return false;
end

function ENT:AcceptInput(name, activator, called, value)
	if (BaseClass.AcceptInput and BaseClass.AcceptInput(self, name, activator, called, value)) then
		return true;
	end

	if (self:AddOutputFromAcceptInput(name, value)) then
		return true;
	end

	return false;
end

function ENT:AddOutputFromAcceptInput(name, value)
	if (name ~= "AddOutput") then
		return false;
	end

	local pos = string.find(value, " ", 1, true);
	if (pos == nil) then
		return false;
	end

	name, value = value:sub(1, pos - 1), value:sub(pos + 1);

	-- This is literally KeyValue but as an input and with ,s as :s.
	value = value:gsub(":", ",");

	return self:AddOutputFromKeyValue(name, value);
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

function ENT:IsWireInputConnected(name)
	return self.Inputs and self.Inputs[name] and IsVaild(self.Inputs[name].Src);
end

function ENT:IsWireOutputConnected(name)
	if (not (self.Outputs and self.Outputs[name])) then
		return false;
	end

	for _, input in pairs(self.Outputs[name].Connected) do
		if (IsValid(input.Entity)) then
			return true;
		end
	end

	return false;
end

-- 'Class' function
function ENT.CanDuplicate(ply, data)
	-- A mixture of duplicator copy/paste & sandbox boilerplate
	if (not duplicator.IsAllowed(data.Class)) then
		return false;
	elseif (not IsValid(ply)) then
		return true;
	end

	local sent_table = scripted_ents.Get(data.Class);

	if (not ply:IsAdmin()) then
		if (not sent_table.Spawnable) then
			return false;
		elseif (sent_table.AdminOnly) then
			return false;
		end
	end

	if (ply.CheckLimit and not ply:CheckLimit(sent_table.CountKey or data.Class)) then
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
		if (ply.AddCount) then ply:AddCount(ent.CountKey or data.Class, ent) end
		if (ply.AddCleanup) then ply:AddCleanup(data.Class, ent) end
	end
	return ent;
end

-- Sandbox's player system, revamped a little
function ENT:SetPlayer(ply)
	self.Founder = ply;
	if (IsValid(ply)) then
		self:SetNWString("FounderName", ply:Nick());
		self.FounderSID = ply:SteamID64();
		-- Legacy
		self.FounderIndex = ply:UniqueID();
	else
		self:SetNWString("FounderName", "");
		self.FounderSID = "";
		self.FounderIndex = 0;
	end
end

function ENT:GetPlayer()
	if (self.Founder == nil) then
		-- SetPlayer has not been called
		return NULL;
	elseif (IsValid(self.Founder)) then
		-- Normal operations
		return self.Founder;
	end
	-- See if the player has left the server then rejoined
	local ply = player.GetBySteamID64(self.FounderSID);
	if (not IsValid(ply)) then
		-- Oh well
		return NULL;
	end
	-- Save us the check next time
	self:SetPlayer(ply);
	return ply;
end

function ENT:GetPlayerName()
	local ply = self:GetPlayer()
	if (IsValid(ply)) then
		return ply:Nick()
	end

	return self:GetNWString("FounderName")
end

-- All or nothing GetPhysicsObject
function ENT:GetValidPhysicsObject()
    local phys = self:GetPhysicsObject();
    if (not phys:IsValid()) then
        local mdl = self:GetModel();
        self:Remove();
        error("No Physics Object available for entity '" .. self.ClassName .. "'! Do you have the model '" .. mdl .. "' installed?", 2);
	end
	return phys;
end
