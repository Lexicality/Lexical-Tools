--[[
	Keypads - lua/weapons/weapon_keypad_cracker/cl_init.lua
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
include("shared.lua");

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
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK);
end

SWEP.SecondaryAttack = SWEP.PrimaryAttack



SWEP._Blink = false;
SWEP._BlinkTimer = 0;
SWEP._BootupSequence = 0

function SWEP:FireAnimationEvent(pos, ang, event, options)
	if (event ~= 7001) then return; end
	self._BootupSequence = string.len(options);
	if (options == "*******") then
		self._BootupSequence = 8;
	end

	-- Always blink the same way
	if (self._BootupSequence == 0) then
		self._Blink = false;
		self._BlinkTimer = CurTime();
	end
end

local texes = {
	logo = "effects/combinedisplay001a",
	map = "effects/prisonmap_disp",
	distortion = "effects/tvscreen_noise002a",
	grid = "vgui/screens/vgui_overlay",
	overlay1 = "dev/dev_prisontvoverlay001",
	overlay2 = "dev/dev_prisontvoverlay002",
}
for name, matname in pairs(texes) do
	texes[name] = surface.GetTextureID(matname);
end

local function drawTex(tex)
	surface.SetTexture(tex);
	surface.DrawTexturedRect(0, 0, 290, 155);
end

function SWEP:DrawScreen()
	local i = self._BootupSequence;
	if (i < 1) then
		return;
	end

	surface.SetDrawColor(color_white);

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
	end

	-- Missing: buttons #5 and #6

	drawTex(texes.distortion);
	if (i == 1) then
		drawTex(texes.grid);
	end
end


local sprmat = Material("sprites/redglow1");
function SWEP:ViewModelDrawn()
	if (not self:IsCracking()) then return end

	local vm = self.Owner:GetViewModel();
	local matt = vm:GetBoneMatrix(vm:LookupBone("v_weapon.c4"));
	local pos = matt:GetTranslation();
	local ang = matt:GetAngles();

	-- Flip the angles round to be relative to the face of the weapon
	-- This makes forward x, right y and up z
	ang:RotateAroundAxis(ang:Forward(),-90);
	ang:RotateAroundAxis(ang:Up(), 180);

	local spritepos = pos
					+ ang:Forward() * 1.59
					+ ang:Right() * 0.26
					+ ang:Up() * 2.86;


	local screenpos = pos
					+ ang:Forward() * 1.8
					+ ang:Right() * -1.3
					+ ang:Up() * 2.69;

	-- Screen
	cam.Start3D2D(screenpos, ang, 0.01);
	self:DrawScreen();
	cam.End3D2D();

	-- Blinkenlite
	if (self._BootupSequence >= 7 and self._Blink) then
		render.SetMaterial(sprmat);
		cam.IgnoreZ(true);
		render.DrawSprite(spritepos, 1, 1, color_white);
		cam.IgnoreZ(false);
	end
end

function SWEP:Think()
	if (not self:IsCracking()) then return; end
	local now = CurTime();
	if (self._BlinkTimer > now) then return; end
	self._BlinkTimer = now + 0.1;
	self._Blink = not self._Blink;
end
