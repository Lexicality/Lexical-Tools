--[[
	NPC Spawn Platforms V2
	Copyright (c) 2011-2016 Lex Robinson
	This code is freely available under the MIT License
--]]
AddCSLuaFile();

ENT.Type           = "anim";
ENT.PrintName      = "Magic Base Thing";
ENT.Author         = "Lex Robinson";
ENT.Purpose        = "Dealing with the garbage that comes from multiple bases";
ENT.Spawnable      = false;
ENT.AdminSpawnable = false;

local BaseClass;
if (WireLib) then
    BaseClass = "base_wire_entity"
elseif (engine.ActiveGameode() == "sandbox") then
    BaseClass = "base_gmodentity"
else
	BaseClass = "base_anim";
end
DEFINE_BASECLASS(BaseClass);

function ENT:SetOverlayText(...)
	if (BaseClass.SetOverlayText) then
		BaseClass.SetOverlayText(self, ...);
	end
end
