--[[
	Keypads - lua/weapons/weapon_keypad_cracker/shared.lua
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

SWEP.Category       = "Roleplay";
SWEP.PrintName      = "Keypad Cracker";
SWEP.Slot           = 4;
SWEP.SlotPos        = 1;
SWEP.DrawAmmo       = false;
SWEP.DrawCrosshair  = true;

SWEP.Author         = "Lexi";
SWEP.Instructions   = "Left click to crack a keypad";
SWEP.Contact        = "";
SWEP.Purpose        = "";

SWEP.ViewModelFOV   = 62;
SWEP.ViewModelFlip  = false;
SWEP.ViewModel      = Model("models/weapons/v_c4.mdl");
SWEP.WorldModel     = Model("models/weapons/w_c4.mdl");
SWEP.RenderGroup    = RENDERGROUP_BOTH

SWEP.Spawnable      = true;
SWEP.AdminOnly      = true;

SWEP.Primary.ClipSize       = -1;
SWEP.Primary.DefaultClip    = -1;
SWEP.Primary.Automatic      = false;
SWEP.Primary.Ammo           = "";

SWEP.Secondary.ClipSize     = -1;
SWEP.Secondary.DefaultClip  = -1;
SWEP.Secondary.Automatic    = false;
SWEP.Secondary.Ammo         = "";

SWEP.States = {
	Idle = 0;
	InitialAnimation = 1;
	Cracking = 2;
	RecoverStage1 = 3;
	RecoverStage2 = 4;
}

function SWEP:GetPrintName()
	return "Keypad Cracker";
end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Cracking");
	self:NetworkVar("Int", 0, "CrackState");
	self:NetworkVar("Entity", 0, "CrackTarget")
	self:NetworkVar("Float", 0, "CrackStart");
	self:NetworkVar("Float", 1, "CrackEnd");
	self:NetworkVar("Float", 1, "RecoveryTimer");
end

-- Utilities
function SWEP:IsTargetEntity(ent)
	return ent:GetClass() == "keypad";
end

function SWEP:IsValidTrace(tr)
	return tr.HitNonWorld and tr.StartPos:Distance(tr.HitPos) <= 50 and self:IsTargetEntity(tr.Entity);
end
