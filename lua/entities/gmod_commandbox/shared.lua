--[[
	~ Command Box ~
	~ Lexi ~
--]]
AddCSLuaFile("shared.lua");
ENT.Type = "anim"
if (WireLib) then
	ENT.Base = "base_wire_entity"
else
	ENT.Base = "base_gmodentity"
end

ENT.PrintName = "Commandbox"
ENT.Author = "Lexi"
ENT.Contact	= "lexi@lexi.org.uk"
ENT.Purpose	= ""
ENT.Instructions = ""
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

if (CLIENT) then
	usermessage.Hook("Commandbox Command Request", function(um)
		local command = um:ReadString();
		Derma_Query("Run Command '" .. command .."'?", "Command Box SENT", "Yes", function() LocalPlayer():ConCommand(command) end, "No", function() end);
	end);
	usermessage.Hook("Commandbox Command", function(um)
		LocalPlayer():ConCommand(um:ReadString())
	end);
	return;
end
umsg.PoolString("Commandbox Command")
umsg.PoolString("Commandbox Command Request")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid   (SOLID_VPHYSICS)
	if (WireLib) then
		WireLib.CreateSpecialInputs(self, {"RunCommand"});
		WireLib.CreateSpecialOutputs(self, {"Command"},{"STRING"});
	end
end

ENT.Command = "";
ENT.Key		= 0; 

local function prest(ply, ent)
	if (not IsValid(ent)) then
		return;
	end
	local command = ent:GetCommand();
	if (ply == ent:GetPlayer()) then
		SendUserMessage("Commandbox Command", ply, command);
	else
		SendUserMessage("Commandbox Command Request", ply, command);
	end	
end
numpad.Register("CommandBox", prest);

function ENT:SetCommand(command)
	self.Command = command;
	self:SetOverlayText("- Command Box -\nCommand: " .. command);
	if (WireLib) then
		Wire_TriggerOutput(self, "Command", command);
	end
end

function ENT:GetCommand()
	return self.Command;
end

function ENT:SetKey(key)
	local ply = self:GetPlayer();
	if (not IsValid(ply)) then
		return;
	end
	if (self.impulse) then
		numpad.Remove(self.impulse);
	end
	self.impulse = numpad.OnUp(ply, key, "CommandBox", self);
	self.key = key;
end

function ENT:GetKey()
	return self.key;
end

function ENT:TriggerInput(key, value)
	if (key == "RunCommand" and value ~= 0) then
		local ply = self:GetPlayer();
		if (not IsValid(ply)) then
			return;
		end
		SendUserMessage("Commandbox Command", ply, self:GetCommand());
	end
end
