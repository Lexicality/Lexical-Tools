--[[
	NPC Spawn Platforms V2
	Copyright (c) 2011-2016 Lex Robinson
	This code is freely available under the MIT License
--]]

ENT.Type           = "anim";
ENT.Base           = "base_gmodentity";
ENT.PrintName      = "NPC Spawn Platform";
ENT.Author         = "Lexi/Devenger";
ENT.Purpose        = "Spawn a constant(ish) stream of NPCs";
ENT.Spawnable      = false;
ENT.AdminSpawnable = true;

local function convert( text )
	-- return npcspawner.npcs[text] or npcspawner.weps[text] or text;
	-- TODO: Look in the "NPC" and "NPCUsableWeapons" lists for the names
	return text;
end

function ENT:UpdateLabel()
	self:SetOverlayText(
		"NPC: "       .. convert(self:GetNWString("npc"    )) ..
		"\nWeapon: "  .. convert(self:GetNWString("weapon" )) ..
		"\nDelay: "   ..         self:GetNWString("delay"  )  ..
		"\nMaximum: " ..         self:GetNWString("maximum")
	);
end

function ENT:GetNPCName()
	return convert(self:GetNWString("npc"));
end
