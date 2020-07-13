--[[
	Keypads - lua/entities/keypad/cl_init.lua
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
]] --
DEFINE_BASECLASS "base_lexentity";

include("shared.lua");

surface.CreateFont("Keypad Key", {
	font   = "Trebuchet MS";
	size   = 18;
	weight = 700
});
surface.CreateFont("Keypad Secure Input", {
	font   = "Lucida Console";
	size   = 34;
});
surface.CreateFont("Keypad Input", {
	font   = "Lucida Console";
	size   = 34;
});
surface.CreateFont("Keypad Input Long", {
	font   = "Lucida Console";
	size   = 26;
});
surface.CreateFont("Keypad Message", {
	font   = "Lucida Console";
	size   = 19;
	weight = 600
});

local keys = {};
do
	local function CreateKeyTab(x, y, w, h, text)
		surface.SetFont("Keypad Key");
		local tw, th = surface.GetTextSize(text);
		local tx = x + w / 2 - tw / 2;
		local ty = y + h / 2 - th / 2;
		return {
			tx,
			ty,
			text,
			x,
			y,
			w,
			h,
		};
	end
	local key = 1;
	local size = 25;
	local gutter = 7.5
	local offset = size + gutter;
	local x = 10;
	local y = 105;
	for j = 2, 0, -1 do
		for i = 0, 2 do
			keys[key] = CreateKeyTab(x + i * offset, y + j * offset, size, size, tostring(key));
			key = key + 1;
		end
	end
	local bigy = 72.5;
	local bigw = 40;
	gutter = 10;
	offset = bigw + gutter;
	keys[10] = CreateKeyTab(x, bigy, bigw, size, "ABORT");
	keys[11] = CreateKeyTab(x + offset, bigy, bigw, size, "OK");
end

surface.SetFont("Keypad Input");
local input_width, input_height = surface.GetTextSize("*");

local button_cutoff = 90 ^ 2;
local visual_cutoff = 750 ^ 2;

ENT.CurrentKey = 11;
ENT.NextCrackNum = 0;

function ENT:Think()
	if (self:IsBeingCracked()) then
		local cn = CurTime();
		if (cn < self.NextCrackNum) then
			return;
		end
		self.NextCrackNum = cn + 0.05;
		self.CurrentKey = math.random(1, 9);
		local edata = EffectData();
		edata:SetOrigin(self:GetZapPos());
		edata:SetNormal(self:GetForward());
		edata:SetScale(1);
		edata:SetMagnitude(1);
		edata:SetRadius(1);
		util.Effect("sparks", edata);
		return;
	end
	self.CurrentKey = nil;
	local tr = LocalPlayer():GetEyeTrace();
	if (tr.Entity ~= self or tr.StartPos:DistToSqr(tr.HitPos) > button_cutoff) then
		return;
	end
	local pos = self:WorldToLocal(tr.HitPos);
	for i, btn in ipairs(self.KeyPositions) do
		local x = (pos.y - btn[1]) / btn[2];
		local y = 1 - (pos.z + btn[3]) / btn[4];
		if (x >= 0 and x <= 1 and y >= 0 and y <= 1) then
			self.CurrentKey = i;
			return;
		end
	end
end

local access_colour = Color(0, 255, 0, 255);
local denied_colour = Color(255, 0, 0, 255);

local secnoise = surface.GetTextureID("effects/tvscreen_noise001a");
local background = Material("keypad/background.png");

-- Horrendous hack to make sprites work
local matCache = {}
local function getSaneMaterial(str)
	local mat
	mat = matCache[str]
	if mat then
		return mat
	end
	mat = Material(str)
	matCache[str] = mat
	if mat:IsError() then
		return mat
	end

	-- Fun with rendermodes ¬_¬
	if mat:GetInt("$spriterendermode") == 0 then
		mat:SetInt("$spriterendermode", 5)
	end
	mat:Recompute()
	return mat
end

-- Draws a burst of light where the beam hits to hide the ugly clipping
function ENT:DrawCrackingLight()
	local target = self:GetZapPos()
	local tr = util.TraceLine({
		start = EyePos(),
		endpos = target,
		filter = { LocalPlayer() },
	})

	if (tr.Entity == self) then
		cam.IgnoreZ(true);
		render.SetMaterial(getSaneMaterial("sprites/glow04"));
		render.DrawSprite(target + self:GetForward() * 0.1, 10, 10, color_white);
		cam.IgnoreZ(false);
	end
end

function ENT:DrawBackground()
	surface.SetMaterial(background);
	surface.SetDrawColor(color_white);
	surface.DrawTexturedRect(0, 0, 110, 210);
end

function ENT:DrawKeys()
	surface.SetFont("Keypad Key");
	surface.SetTextColor(color_black);
	for i, data in pairs(keys) do
		if (self.CurrentKey == i) then
			if (i == 10) then
				surface.SetDrawColor(255, 0, 0);
			elseif (i == 11) then
				surface.SetDrawColor(0, 255, 0);
			else
				surface.SetDrawColor(255, 255, 255);
			end
			surface.DrawRect(data[4], data[5], data[6], data[7]);
		end
		surface.SetTextPos(data[1], data[2]);
		surface.DrawText(data[3]);
	end
end

function ENT:DrawCrackingScreen()
	surface.SetTexture(secnoise);
	local scroll = CurTime() - math.floor(CurTime());
	surface.DrawTexturedRectUV(9, 9, 92, 51, 0, scroll, 0.3, scroll + 1);
end

-- This is copy/paste code because it's easier to read like this
function ENT:DrawAccessGranted()
	surface.SetFont("Keypad Message");
	surface.SetTextColor(access_colour);

	surface.SetTextPos(19, 16);
	surface.DrawText("ACCESS");
	surface.SetTextPos(13, 35);
	surface.DrawText("GRANTED");
end

function ENT:DrawAccessDenied()
	surface.SetFont("Keypad Message");
	surface.SetTextColor(denied_colour);

	surface.SetTextPos(19, 16);
	surface.DrawText("ACCESS");
	surface.SetTextPos(19, 35);
	surface.DrawText("DENIED");
end

function ENT:DrawSecureInput(input)
	surface.SetFont("Keypad Secure Input");
	surface.SetTextColor(color_white);
	local inputLen = string.len(input);
	if (inputLen <= 4) then
		surface.SetTextPos(15, 24);
		surface.DrawText(string.rep("*", inputLen));
	else
		inputLen = math.min(inputLen, 8);
		surface.SetTextPos(15, 13);
		surface.DrawText(string.rep("*", 4));
		surface.SetTextPos(15, 34);
		surface.DrawText(string.rep("*", inputLen - 4));
	end
end

function ENT:DrawInsecureInput(input)
	surface.SetTextColor(color_white);
	local inputLen = string.len(input);
	if (inputLen <= 4) then
		surface.SetFont("Keypad Input");
		surface.SetTextPos(15, 20);
		surface.DrawText(input);
	else
		surface.SetFont("Keypad Input Long");
		surface.SetTextPos(22, 11);
		surface.DrawText(string.sub(input, 1, 4));
		surface.SetTextPos(22, 35);
		surface.DrawText(string.sub(input, 5, 8));
	end
end

function ENT:Draw()
	self:DrawModel();

	if (LocalPlayer():GetShootPos():DistToSqr(self:GetPos()) > visual_cutoff) then
		return;
	end

	local pos = self:GetPos() + (self:GetForward() * 1.02) + (self:GetRight() * 2.75) + (self:GetUp() * 5.25);
	local ang = self:GetAngles();

	ang:RotateAroundAxis(ang:Right(), -90);
	ang:RotateAroundAxis(ang:Up(),     90);

	cam.Start3D2D(pos, ang, 0.05);
		-- Draw the background
		self:DrawBackground();
		self:DrawKeys();

		local status = self:GetStatus();
		local input = self:GetPasswordDisplay();
		if (self:IsBeingCracked()) then
			self:DrawCrackingScreen();
		elseif (status ~= self.STATUSES.Normal) then
			if (status == self.STATUSES.AccessGranted) then
				self:DrawAccessGranted();
			else
				self:DrawAccessDenied();
			end
		elseif (input ~= "") then
			if (self:IsSecure()) then
				self:DrawSecureInput(input);
			else
				self:DrawInsecureInput(input);
			end
		end
	cam.End3D2D();

	if (self:IsBeingCracked()) then
		self:DrawCrackingLight();
	end
end
