--[[
	Keypads - lua/weapons/weapon_keypad_cracker.lua
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

if (SERVER) then
	CreateConVar("keypad_cracker_time", 15, FCVAR_REPLICATED + FCVAR_ARCHIVE, "How many seconds it takes to crack a keypad");
end

function SWEP:GetCrackTime(target)
	return cvars.Number("keypad_cracker_time", 15)
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

function SWEP:ResetState()
	self:SetWeaponHoldType("slam");
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

	self:SetWeaponHoldType("duel");
	self:SetCrackTarget(ent);


	-- Play the bootup animation
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK);
	self:SetCrackState(self.States.InitialAnimation);

	-- Don't actually start cracking after the 7th button press in the bootup animation (~2s)
	local length = self:SequenceDuration() - 0.64990234375; -- Scientifically discovered 100% correct number
	local start = CurTime() + length;
	self:SetCrackStart(start);
	self:SetCrackEnd(start + self:GetCrackTime(ent));
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
		self._Blink = math.floor(CurTime() * 10) % 2 == 0;
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





SWEP._Blink = false;
SWEP._BootupSequence = 0

function SWEP:FireAnimationEvent(pos, ang, event, options)
	if (event ~= 7001) then return; end
	self._BootupSequence = string.len(options);
	if (options == "*******") then
		self._BootupSequence = 8;
	end
end

local sprmat = Material("sprites/redglow1");
local beammat = Material("cable/blue_elec");
local texes = {
	logo = "effects/combinedisplay001a",
	map = "effects/prisonmap_disp",
	distortion = "effects/tvscreen_noise002a",
	grid = "vgui/screens/vgui_overlay",
	overlay1 = "dev/dev_prisontvoverlay001",
	overlay2 = "dev/dev_prisontvoverlay002",
}
if (CLIENT) then
	for name, matname in pairs(texes) do
		texes[name] = surface.GetTextureID(matname);
	end

	surface.CreateFont("GarbageText", {
		font   = "Verdana",
		weight = 1200,
		size   = 6,
		blursize = 1,
		additive=true,
		-- scanlines=2,
		-- shadow=true,
	});

end

local function drawTex(tex)
	surface.SetTexture(tex);
	surface.DrawTexturedRect(0, 0, 290, 155);
end

local lipsum = {
	"Lorem ipsum dolor sit amet,",
	"consectetur adipiscing elit.",
	"Suspendisse feugiat finibus",
	"laoreet. Ut venenatis id",
	"felis at feugiat. Cras ut",
	"tristique sapien. Nulla",
	"iaculis massa ac pretium ornare.",
	"Suspendisse iaculis, arcu id",
	"interdum feugiat, lectus nisl",
	"feugiat augue, et tempor nulla",
	"odio et nisl. Vestibulum eget",
	"maximus turpis, in aliquet ex.",
	"Phasellus magna elit, elementum",
	"ac sapien sit amet, scelerisque",
	"fermentum dolor. Donec vel",
	"tortor sapien. Nam sollicitudin",
	"scelerisque nulla nec maximus.",
}
function SWEP:DrawScreen()
	local i = self._BootupSequence;
	if (i < 1) then
		return;
	end

	surface.SetDrawColor(color_white);
	surface.SetAlphaMultiplier(1);

	if (i >= 2 and i <= 7) then
		drawTex(texes.logo);
		drawTex(texes.grid);
	elseif (i >= 8) then
		drawTex(texes.map);
	end

	if (i >= 3) then
		drawTex(texes.overlay1);
	end
	if (i >= 4) then
		drawTex(texes.overlay2);
		surface.SetAlphaMultiplier(0.8);
		surface.DrawOutlinedRect(223, 74, 69, 10);
	end

	-- Bouncing bars of nonsense
	if (i >= 5) then
		local now = CurTime() * 2;
		-- Left hand side
		local len = -32;
		len = len * ((math.sin(now) * math.sin(now * 2.7) + 1) / 2)
		surface.DrawRect(255, 69, len, 3)
		local len = -32;
		len = len * ((math.cos(now * 2) * math.sin(now * 1.2) + 1) / 2)
		surface.DrawRect(255, 72, len, 2)
		-- Right hand side
		local len = 34
		len = len * ((math.cos(now * 5) * math.cos(now * 1.2) + 1) / 2)
		surface.DrawRect(255, 69, len, 2)
		local len = 34
		len = len * ((math.cos(now) * math.cos(now * 1.2) + 1) / 2)
		surface.DrawRect(255, 71, len, 2)
		local len = 34
		len = len * ((math.cos(now) + 1) / 2)
		surface.DrawRect(255, 73, len, 2)
	end

	-- Actually useful bar
	if (i >= 7) then
		local startTime = self:GetCrackStart();
		local endTime = self:GetCrackEnd();
		local now = CurTime();
		if (now > startTime) then
			local max = endTime - startTime;
			local cur = now - startTime;
			cur = math.min(cur, max);
			local len = cur / max;
			surface.DrawRect(223, 74, 69 * len, 10);
		end
	end

	surface.SetAlphaMultiplier(1);

	if (i >= 6) then
		local now = CurTime() * 50;
		surface.SetTextColor(color_white);
		surface.SetFont("GarbageText");
		local _, h = surface.GetTextSize('M');
		local num = #lipsum;
		local sx, sy = 67, 70;
		-- Idiotic stenciling to make the text look nice
		surface.SetDrawColor(color_black);
		-- Stencil boilerplate
		render.ClearStencil()
		render.SetStencilEnable(true)
		-- Bitwise mask of what to read/write. We're not being clever here, so just use bit #1
		render.SetStencilWriteMask(1)
		render.SetStencilTestMask(1)
		-- This could be anything as long as it bitwises with 1, but pick 1 because that's unsuprising
		render.SetStencilReferenceValue(1)
		-- We don't want to actually draw the box, so always fail
		render.SetStencilCompareFunction(STENCIL_NEVER)
		-- When the boxs fails, draw the result to the buffer
		render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
		-- Fail to draw a box
		surface.DrawRect(sx - 2, sy + 20, 105, 50)
		-- Now, only draw things in the stencil buffer
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		-- Prevent the text from putting itself into the stencil buffer
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		-- Draw all of the text
		for i, line in ipairs(lipsum) do
			local voffset = (i - 1) * h
			-- This just works, don't ask me how.
			voffset = voffset - (now % (num * h));
			if (voffset < 0) then
				voffset = voffset + num * h;
			end
			surface.SetTextPos(sx, sy + voffset);
			surface.DrawText(line);
		end
		render.SetStencilEnable(false)
	end

	drawTex(texes.distortion);
	if (i == 1) then
		drawTex(texes.grid);
	end
end

function SWEP:ViewModelDrawn(vm)
	local state = self:GetCrackState();
	if (state ~= self.States.InitialAnimation and state ~= self.States.Cracking) then
		return
	end

	local matt = vm:GetBoneMatrix(vm:LookupBone("v_weapon.c4"));
	local pos = matt:GetTranslation();
	local ang = matt:GetAngles();

	-- Flip the angles round to be relative to the face of the weapon
	-- This makes forward x, right y and up z
	ang:RotateAroundAxis(ang:Forward(),-90);
	ang:RotateAroundAxis(ang:Up(), 180);

	-- Screen
	local screenpos = pos
		+ ang:Forward() * 1.8
		+ ang:Right() * -1.3
		+ ang:Up() * 2.70;

	cam.Start3D2D(screenpos, ang, 0.01);
	self:DrawScreen();
	cam.End3D2D();

	-- Everything else is for post bootup
	if (state ~= self.States.Cracking) then
		return;
	end

	-- Blinkenlite
	if (self._Blink) then
		local spritepos = pos
			+ ang:Forward() * 1.59
			+ ang:Right() * 0.26
			+ ang:Up() * 2.86;

		render.SetMaterial(sprmat);
		cam.IgnoreZ(true);
		render.DrawSprite(spritepos, 1, 1, color_white);
		cam.IgnoreZ(false);
	end

	-- Zappy
	cam.Start3D();
	self:DrawMagicBeam(pos);
	cam.End3D();
end

function SWEP:DrawWorldModel()
	self:DrawModel();
end

function SWEP:DrawWorldModelTranslucent()
	if (
		self:GetCrackState() ~= self.States.Cracking
		or self:GetCrackStart() > CurTime()
		or not IsValid(self:GetCrackTarget())
	) then
		return;
	end

	local bone = self:LookupBone("ValveBiped.Bip01_R_Hand")
	if (not bone) then return; end
	local matt = self:GetBoneMatrix(bone);
	local pos = matt:GetTranslation();

	pos = pos
		+ matt:GetForward() * 5
		+ matt:GetRight() * 5;

	self:DrawMagicBeam(pos);
end

function SWEP:DrawMagicBeam(pos)
	local target = self:GetCrackTarget();
	if (not IsValid(target)) then return; end
	local targetPos = target:GetZapPos()

	-- Avoid the beam being stretched by the breathing animation
	local dist = pos:Distance(targetPos) / 7;
	local mat_start = dist;
	local mat_end = 0;

	-- Make the beam scroll into the keypad
	local n = CurTime()
	mat_start = mat_start + n;
	mat_end = mat_end + n;

	render.SetMaterial(beammat);
	render.DrawBeam(
		pos,
		targetPos,
		6,
		mat_start,
		mat_end,
		color_white
	);

	n = n * 1.2

	mat_start = mat_start + n;
	mat_end = mat_end + n;

	render.DrawBeam(
		pos,
		targetPos,
		5,
		mat_start,
		mat_end,
		color_white
	);
end
