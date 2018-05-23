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
	self:SetCrackState(self.States.Idle);
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
	self:SetCrackState(self.States.RecoverStage1);
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK);
	self:SetRecoveryTimer(CurTime() + self:SequenceDuration());
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
	if (self:GetCrackState() ~= self.States.Idle) then
		return;
	end

	local tr = self.Owner:GetEyeTrace();
	if (not self:IsValidTrace(tr)) then
		return;
	end
	local ent = tr.Entity;

	self:SetWeaponHoldType("pistol");
	self:SetCrackTarget(ent);


	-- Play the bootup animation
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK);
	self:SetCrackState(self.States.InitialAnimation);

	-- Don't actually start cracking after the 7th button press in the bootup animation (~2s)
	local length = self:SequenceDuration() - 0.64990234375; -- Scientifically discovered 100% correct number
	local start = CurTime() + length;
	self:SetCrackStart(start);
	self:SetCrackEnd(start + self.CrackTime);
end

SWEP.SecondaryAttack = SWEP.PrimaryAttack

function SWEP:CheckFailState()
	-- Make sure the keypad still exists
	local target = self:GetCrackTarget();
	if (not IsValid(target)) then
		self:Fail();
		return true;
	end
	-- Make sure they haven't moved
	local tr = self.Owner:GetEyeTrace();
	if (tr.Entity ~= target or not self:IsValidTrace(tr)) then
		self:Fail();
		return true;
	end

	return false;
end

function SWEP:Think()
	local state = self:GetCrackState();
	if (state == self.States.Idle) then
		return;
	end

	local now = CurTime();
	if (state == self.States.InitialAnimation) then
		-- Waiting for the animation to end
		if (self:CheckFailState()) then
			return
		elseif (self:GetCrackStart() <= now) then
			self:GetCrackTarget():SetBeingCracked(true);
			self:SetCrackState(self.States.Cracking);
		end
	elseif (state == self.States.Cracking) then
		-- Crack testing
		if (self:CheckFailState()) then
			return
		elseif (self:GetCrackEnd() <= now) then
			self:Succeed();
		end
	elseif (state == self.States.RecoverStage1) then
		if (self:GetRecoveryTimer() <= now) then
			self:SetCrackState(self.States.RecoverStage2);
			self:SendWeaponAnim(ACT_VM_DRAW);
			self:SetRecoveryTimer(CurTime() + self:SequenceDuration());
		end
	elseif (state == self.States.RecoverStage2) then
		if (self:GetRecoveryTimer() <= now) then
			self:SetCrackState(self.States.Idle);
			self:SendWeaponAnim(ACT_VM_IDLE);
		end
	else
		ErrorNoHalt("Keypad cracker got into unknown state " .. state .. "!");
		self:ResetState();
		self:SendWeaponAnim(ACT_VM_IDLE);
	end
end
