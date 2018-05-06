--[[
	Keypads - lua/weapons/weapon_keypad_tester.lua
    Copyright 2012-2018 Lex Robinson

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

SWEP.Category       = "Roleplay"
SWEP.PrintName      = "Keypad Tester"
SWEP.Author         = "Lexi"
SWEP.Instructions   = "Left click to instantly fire a keypad";
SWEP.DrawAmmo       = false
SWEP.Primary.Ammo   = ""
SWEP.Slot           = 5

SWEP.Spawnable      = true;
SWEP.AdminOnly      = true;

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + .4)
    local tr = self.Owner:GetEyeTrace();
    if (SERVER and self.Owner:IsAdmin() and IsValid(tr.Entity) and tr.Entity:GetClass() == "keypad") then
    	tr.Entity:TriggerKeypad(true);
    end
end
