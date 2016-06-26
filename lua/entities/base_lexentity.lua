--[[
	Universal Entity Base
	Copyright (c) 2016 Lex Robinson
	This code is freely available under the MIT License
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
print("!")

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

function ENT:AcceptInput(name, activator, called, value)
	if (BaseClass.AcceptInput) then BaseClass.AcceptInput(self, name, activator, called, value); end

	if (name:lower() == "addoutput") then
		-- Hammer IO (magic)
		-- TODO value is in the form of "<key> <magic>", where <magic> /may/ contain spaces.
		error("Not implemented yet!");
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
