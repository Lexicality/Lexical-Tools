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
end

SWEP.SecondaryAttack = SWEP.PrimaryAttack

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
local sprmat = Material("sprites/redglow1");
function SWEP:ViewModelDrawn()
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
		surface.SetDrawColor(color_white);
		for _, tex in ipairs(texes) do
			surface.SetTexture(tex);
			surface.DrawTexturedRect(0, 0, 290, 155);
		end
	cam.End3D2D();

	-- Blinkenlite
	render.SetMaterial(sprmat);
	cam.IgnoreZ(true);
	render.DrawSprite(spritepos, 1, 1, color_white);
	cam.IgnoreZ(false);
end

function SWEP:Think()
	DebugInfo(1, self.Owner:GetViewModel():GetCycle());
end
