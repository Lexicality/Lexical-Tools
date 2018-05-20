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

SWEP.CrackTime = 15; -- seconds

function SWEP:ResetState()
	self:SetWeaponHoldType("normal");
	local target = self:GetCrackTarget()
	if (IsValid(target)) then
		target:SetBeingCracked(false);
	end
	self:SetCracking(false);
	self:SetCrackTarget(NULL);
	self:SetCrackStart(0);
	self:SetCrackEnd(0);
end

function SWEP:Initialize()
	self:ResetState();
end

function SWEP:Succeed()
	local target = self:GetCrackTarget()
	if (SERVER and IsValid(target)) then
		target:TriggerKeypad(true);
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
	if (self:IsCracking()) then
		return;
	end

	local tr = self.Owner:GetEyeTrace();
	if (not self:IsValidTrace(tr)) then
		return;
	end
	local ent = tr.Entity;

	self:SetWeaponHoldType("pistol");
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK);

	local start = CurTime();
	self:SetCrackStart(start);
	self:SetCrackEnd(start + self.CrackTime);
	self:SetCracking(true);
	self:SetCrackTarget(ent);

	ent:SetBeingCracked(true);
end

SWEP.SecondaryAttack = SWEP.PrimaryAttack

function SWEP:Think()
	if (not self:IsCracking()) then
		return;
	end
	-- Make sure they haven't moved
	local tr = self.Owner:GetEyeTrace();
	if (not (self:IsValidTrace(tr) and tr.Entity == self:GetCrackTarget())) then
		self:Fail();
		return;
	end
	-- Crack testing
	if (self:GetCrackEnd() <= CurTime()) then
		self:Succeed();
	end
end
