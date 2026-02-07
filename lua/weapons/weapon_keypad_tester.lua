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
]]
AddCSLuaFile()

SWEP.Category = "Roleplay"
SWEP.PrintName = "Keypad Tester"
SWEP.Author = "Lexi"
SWEP.Instructions = "Left click to gain access, Right click to be denied"
SWEP.DrawAmmo = false
SWEP.Primary.Ammo = ""
SWEP.Secondary.Ammo = ""
SWEP.Slot = 5

SWEP.Spawnable = true
SWEP.AdminOnly = true

function SWEP:CanTrigger(keypad)
	if not IsValid(keypad) or keypad:GetClass() ~= "keypad" then
		return false
	end

	local ply = self.Owner
	local victim = keypad:GetPlayer()
	return ply == victim or ply:IsAdmin()
end

function SWEP:Keypadify(state)
	local keypad = self.Owner:GetEyeTrace().Entity
	if self:CanTrigger(keypad) then
		-- TODO: Particle effects
		if SERVER then
			keypad:TriggerKeypad(state, self.Owner)
		end
	end
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.4)
	self:Keypadify(true)
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.4)
	self:Keypadify(false)
end
