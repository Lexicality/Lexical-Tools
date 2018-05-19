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
    self:SetWeaponHoldType("normal")
    self.Cracking = false;
    if (IsValid(self.CrackTarget)) then
        self.CrackTarget.dt.Cracking = false;
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
end

function SWEP:Fail()
    self:ResetState();
end

function SWEP:Holster()
    self:Fail();
    return true;
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + .4)
	if (self.Cracking) then
        return;
    end
    local tr = self.Owner:GetEyeTrace();
    local ent = tr.Entity;
    if (not (cancrack(tr) and self:IsTargetEntity(ent))) then
        return;
    end

    self.CrackStart = CurTime()

    local team = self.Owner:Team();
    -- Alow (super) admin on duty to break in instantly (for base testing)
    if (team == TEAM_ADMIN or team == TEAM_SADMIN) then
        self.CrackEnd = self.CrackStart + 0.1;
	else
        self.CrackEnd = self.CrackStart + self.CrackTime;
    end

    self:SetWeaponHoldType("pistol")

    self.Cracking = true;
    self.CrackTarget = ent;
    ent.dt.Cracking = true;
    if (team == TEAM_ADMIN or team == TEAM_SADMIN) then
        self:Succeed();
        return;
    end
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
