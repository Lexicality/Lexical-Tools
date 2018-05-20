--[[
	Keypads - lua/weapons/weapon_keypad_cracker/init.lua
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

AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
include("shared.lua");

-- Utilities
local function cancrack(tr)
	return tr.HitNonWorld and tr.StartPos:Distance(tr.HitPos) <= 300
end

SWEP.Cracking = false;
SWEP.CrackStart = 0;
SWEP.CrackEnd = 0;
SWEP.CrackTarget = NULL;
SWEP.Timer = 0;

function SWEP:ResetState()
	self:SetWeaponHoldType("normal");
	self.Cracking = false;
	if (IsValid(self.CrackTarget)) then
		self.CrackTarget:SetBeingCracked(false);
	end
	self.CrackTarget = NULL;
	self.Timer = 0;
end

function SWEP:Initialize()
	self:ResetState();
end

function SWEP:Succeed()
	if (SERVER and IsValid(self.CrackTarget)) then
		self.CrackTarget:TriggerKeypad(true);
	end
	self:ResetState();
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK);
end

function SWEP:Fail()
	self:ResetState();
	-- :/ this is really abrupt, but it's what CS:S does and I can't work out how to blend the anims
	self:SendWeaponAnim(ACT_VM_IDLE);
end

function SWEP:Holster()
	self:Fail();
	return true;
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + .4);
	if (self.Cracking) then
		return;
	end
	local tr = self.Owner:GetEyeTrace();
	local ent = tr.Entity;
	if (not (cancrack(tr) and self:IsTargetEntity(ent))) then
		return;
	end

	self.CrackStart = CurTime();
	self.CrackEnd = self.CrackStart + self.CrackTime;

	self:SetWeaponHoldType("pistol");
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK);

	self.Cracking = true;
	self.CrackTarget = ent;
	ent:SetBeingCracked(true);
end

SWEP.SecondaryAttack = SWEP.PrimaryAttack

function SWEP:Think()
	if (not self.Cracking) then
		return;
	end
	-- Make sure they haven't moved
	local tr = self.Owner:GetEyeTrace();
	if (not (cancrack(tr) and tr.Entity == self.CrackTarget)) then
		self:Fail();
		return;
	end
	-- Crack testing
	if (self.CrackEnd <= CurTime()) then
		self:Succeed();
	end
end
