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

-- Play a lovely animation to indicate the end of cracking
-- This should take ~2 seconds, depending on timer resolution.
function SWEP:DoRecovery()
	self:SetRecovering(true);

	-- Play the drop animation
	local id, length = self:LookupSequence("drop");
	local seq = self:GetSequenceInfo(id);
	self:SendWeaponAnim(seq.activity);
	timer.Simple(length, function()
		if (not IsValid(self)) then return; end

		-- Play the undrop anmiation
		local id, length = self:LookupSequence("draw");
		local seq = self:GetSequenceInfo(id);
		self:SendWeaponAnim(seq.activity);
		timer.Simple(length, function()
			if (not IsValid(self)) then return; end

			self:SetRecovering(false);
			self:SendWeaponAnim(ACT_VM_IDLE);
		end);
	end);
end

function SWEP:Succeed()
	local target = self:GetCrackTarget()
	if (SERVER and IsValid(target)) then
		target:TriggerKeypad(true);
	end
	self:ResetState();
	self:DoRecovery();
end

function SWEP:Fail()
	local start = self:GetCrackStart();

	self:ResetState();

	if (start > CurTime()) then
		-- :/ this is really abrupt, but it's what CS:S does and I can't work out how to blend the anims
		self:SendWeaponAnim(ACT_VM_IDLE);
	else
		self:DoRecovery();
	end
end

function SWEP:Holster()
	self:ResetState();
	return true;
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + .4);
	if (self:IsCracking() or self:IsRecovering()) then
		return;
	end

	local tr = self.Owner:GetEyeTrace();
	if (not self:IsValidTrace(tr)) then
		return;
	end
	local ent = tr.Entity;

	self:SetWeaponHoldType("pistol");

	self:SetCracking(true);
	self:SetCrackTarget(ent);

	-- Play the bootup animation
	local id, length = self:LookupSequence("pressbutton");
	local seq = self:GetSequenceInfo(id);
	self:SendWeaponAnim(seq.activity);

	-- Don't actually start cracking after the bootup animation (~2.7s)
	local start = CurTime() + length;
	self:SetCrackStart(start);
	self:SetCrackEnd(start + self.CrackTime);
	timer.Simple(length, function()
		if (IsValid(self) and self:IsCracking() and self:GetCrackTarget() == ent) then
			ent:SetBeingCracked(true);
		end
	end);
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
