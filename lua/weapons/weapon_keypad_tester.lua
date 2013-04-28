--[[
    Keypad Tester
    Copyright (c) 2013 Lex Robinson
    This code is freely available under the MIT License
--]]

AddCSLuaFile();

SWEP.Category       = "Roleplay"
SWEP.PrintName      = "Keypad Tester"
SWEP.Author         = "Lex Robinson"
SWEP.Instructions   = "Left click to instantly fire a keypad";
SWEP.DrawAmmo       = false
SWEP.Primary.Ammo   = ""
SWEP.Slot           = 5

SWEP.Spawnable      = true; 
SWEP.AdminOnly      = true;

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + .4)
    local tr = self.Owner:GetEyeTrace();
    if (SERVER and self.Owner:IsAdmin() and IsValid(tr.Entity) and tr.Entity:GetClass() == 'sent_keypad') then
    	tr.Entity:TriggerKeypad(true);
    end
end
