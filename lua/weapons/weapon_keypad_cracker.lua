--[[
    Cracking base
    Should serve for cracker, lockpick and super varients thereon
--]]

--SWEP.Category       = "DarkRP"
SWEP.PrintName      = "Keypad Cracker v2"
SWEP.Slot           = 4
SWEP.SlotPos        = 1
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = true

SWEP.Author         = "Lexi"
SWEP.Instructions   = "Left click to crack a keypad";
SWEP.Contact        = ""
SWEP.Purpose        = ""

SWEP.ViewModelFOV   = 62;
SWEP.ViewModelFlip  = false;
SWEP.ViewModel      = Model("models/weapons/v_c4.mdl");
SWEP.WorldModel     = Model("models/weapons/w_c4.mdl");

SWEP.Spawnable      = false;
SWEP.AdminSpawnable = true;

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = ""


SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = ""

--[[
    START CUSTOMISATIONY BITS
    OVERRIDE THESE IN YOUR DERIVATION
--]]

SWEP.CrackTime = 15; -- seconds

-- Utilities
function SWEP:IsTargetEntity(ent)
    return string.find(ent:GetClass(), "sent_keypad");
end
function SWEP:DoNoise()
    if (self.Owner:Team() ~= TEAM_HITMAN) then
        self:EmitSound("buttons/blip2.wav", 60, 200)
    end
end
function SWEP:GetPrintName()
    return "A badly designed " .. self.ClassName .. "!";
end

-- Required Callbacks
function SWEP:OnSuccess()
    if (CLIENT) then
        return;
    end
    local ent = self.CrackTarget;
    if (IsValid(ent)) then
        ent:TriggerKeypad(true);
    end
end
function SWEP:OnFailure()
end

-- Misc callabcks
function SWEP:OnStart()
end
function SWEP:OnReset()
end

--[[
    OK STOP OVERIDING SHIT NOW K
--]]

local function cancrack(tr)
    return tr.HitNonWorld and tr.StartPos:Distance(tr.HitPos) <= 300
end

SWEP.Cracking = false;
SWEP.CrackStart = 0;
SWEP.CrackEnd = 0;
SWEP.CrackTarget = NULL;

function SWEP:Initialize()
    self:ResetState();
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
    self:OnStart();
    if (team == TEAM_ADMIN or team == TEAM_SADMIN) then
        self:Succeed();
        return;
    end
end

SWEP.Timer = 0;

function SWEP:ResetState()
    self:OnReset();
	self:SetWeaponHoldType("normal")
    self.Cracking = false;
    self.CrackTarget = NULL;
    self.Timer = 0;
end

function SWEP:Think()
    if (not self.Cracking) then
        return;
    end
    -- Make sure they haven't movedthrakerzod
    local tr = self.Owner:GetEyeTrace();
    if (not (cancrack(tr) and tr.Entity == self.CrackTarget)) then
        self:Fail();
        return;
    end
    -- Timers
    local ft = FrameTime();
    self.Timer = self.Timer + FrameTime();
    if (CLIENT) then
        if (self.Timer > 0.5) then
            self.Timer = 0;
            self:_hudtimer();
        end
    else
        if (self.Timer > 1) then
            self.Timer = 0;
            self:DoNoise();
        end
    end
    -- Crack testing
    if (self.CrackEnd <= CurTime()) then
        self:Succeed();
    end
end

function SWEP:Succeed()
    self:OnSuccess();
    self:ResetState();
end

function SWEP:Fail()
    self:OnFailure();
    self:ResetState();
end

function SWEP:Holster()
    self:Fail();
    return true;
end

SWEP.SecondaryAttack = SWEP.PrimaryAttack

if (SERVER) then
    return;
end

-- This code belongs to whoever wrote the lockpick SWEP. I disavow all ownership of it, including the edits I have made.
local dots = {
    [3] = "";
    [0] = ".";
    [1] = "..";
    [2] = "...";
}
SWEP.Dots = "";
function SWEP:_hudtimer()
    self.Dots = dots[#self.Dots];
end

function SWEP:DrawHUD()
    if (not self.Cracking) then
        return;
    end
    local w = ScrW()
    local h = ScrH()
    local x,y,width,height = w/2-w/10, h/ 2, w/5, h/15
    draw.RoundedBox(8, x, y, width, height, Color(10,10,10,120))

    local status = (CurTime() - self.CrackStart) / self.CrackTime;
    local BarWidth = status * (width - 16) + 8
    draw.RoundedBox(8, x+8, y+8, BarWidth, height - 16, Color(255-(status*255), 0+(status*255), 0, 255))

    draw.SimpleText("Cracking" .. self.Dots, "Trebuchet24", w/2, h/2 + height/2, Color(255,255,255,255), 1, 1)
end

local texes = {
    -- "effects/combinedisplay001a",
    "effects/prisonmap_disp",
    -- "effects/combine_binocoverlay",
    "effects/tvscreen_noise002a",
    "vgui/screens/vgui_overlay",
    "dev/dev_prisontvoverlay001",
    "dev/dev_prisontvoverlay002",
    -- "dev/dev_prisontvoverlay003",
    -- "dev/dev_prisontvoverlay004",
}
for i, name in ipairs(texes) do
    texes[i] = surface.GetTextureID(name);
end
local sprmat = Material('sprites/ledglow');
function SWEP:ViewModelDrawn()
    local vm = self.Owner:GetViewModel();
    local matt = vm:GetBoneMatrix(vm:LookupBone('v_weapon.c4'));
    local pos = matt:GetTranslation();
    local ang = matt:GetAngles();
    render.SetMaterial(sprmat)
    render.SetBlend(0.1);
    render.DrawSprite(pos
                        + ang:Forward() * -1.6
                        + ang:Up() * -0.25
                        + ang:Right() * -2.8
                    , 1, 1, color_white);
    render.SetBlend(1);
    pos = pos + ang:Forward() * -1.8 + ang:Right() * -2.7 + ang:Up() * 1.3;
    ang:RotateAroundAxis(ang:Forward(),-90);
    ang:RotateAroundAxis(ang:Up(), 180);
    cam.Start3D2D(pos, ang, 0.01);
        surface.SetDrawColor(color_white);
        for _, tex in ipairs(texes) do
            surface.SetTexture(tex);
            surface.DrawTexturedRect(0, 0, 290, 155);
        end
    cam.End3D2D();
end