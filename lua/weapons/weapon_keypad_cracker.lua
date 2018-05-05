--[[
    Keypad Cracker
    Copyright (c) 2013 Lex Robinson
    This code is freely available under the MIT License
--]]

AddCSLuaFile();

SWEP.Category       = "Roleplay"
SWEP.PrintName      = "Keypad Cracker"
SWEP.Slot           = 4
SWEP.SlotPos        = 1
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = true

SWEP.Author         = "Lex Robinson"
SWEP.Instructions   = "Left click to crack a keypad";
SWEP.Contact        = ""
SWEP.Purpose        = ""

SWEP.ViewModelFOV   = 62;
SWEP.ViewModelFlip  = false;
SWEP.ViewModel      = Model("models/weapons/v_c4.mdl");
SWEP.WorldModel     = Model("models/weapons/w_c4.mdl");

SWEP.Spawnable      = true; 
SWEP.AdminOnly      = true;

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = ""

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = ""

function SWEP:GetPrintName()
    return "Keypad Cracker";
end

SWEP.CrackTime = 15; -- seconds

-- Utilities
function SWEP:IsTargetEntity(ent)
    return ent:GetClass() == "sent_keypad";
end

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


--[[

        Meat & Veg

--]]

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


local frames = {
    28, -- LED on
    37, -- Screen on (flicker)
    45, -- Overlay1 on
    51, -- Overlay2 on
    57, -- background on
    63, -- EMP the keypad
    67, -- start flashing
}
local maxframes = 83;
local sequenceduration = 2.7666666556729

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

SWEP.SecondaryAttack = SWEP.PrimaryAttack

if (SERVER) then
    return;
end

local texes = {
    -- "effects/combinedisplay001a",
    "effects/prisonmap_disp",
    "effects/tvscreen_noise002a",
    "vgui/screens/vgui_overlay",
    "dev/dev_prisontvoverlay001",
    "dev/dev_prisontvoverlay002",
}
for i, name in ipairs(texes) do
    texes[i] = surface.GetTextureID(name);
end
local sprmat = Material('sprites/redglow1');
function SWEP:ViewModelDrawn()
    local vm = self.Owner:GetViewModel();
    local matt = vm:GetBoneMatrix(vm:LookupBone('v_weapon.c4'));
    local pos = matt:GetTranslation();
    local ang = matt:GetAngles();
    local spritepos = pos
                    + ang:Forward() * -1.6
                    + ang:Up() * -0.25
                    + ang:Right() * -2.8;
    local screenpos = pos
                    + ang:Forward() * -1.8
                    + ang:Right() * -2.7
                    + ang:Up() * 1.3;
    ang:RotateAroundAxis(ang:Forward(),-90);
    ang:RotateAroundAxis(ang:Up(), 180);
    cam.Start3D2D(screenpos, ang, 0.01);
        surface.SetDrawColor(color_white);
        for _, tex in ipairs(texes) do
            surface.SetTexture(tex);
            surface.DrawTexturedRect(0, 0, 290, 155);
        end
    cam.End3D2D();
    render.SetMaterial(sprmat)
    cam.IgnoreZ(true);
    render.DrawSprite(spritepos, 1, 1, color_white);
    cam.IgnoreZ(false);
end

function SWEP:Think()
    DebugInfo(1, self.Owner:GetViewModel():GetCycle());
end
