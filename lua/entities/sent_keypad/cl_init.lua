include('shared.lua')

local KeyPos = {
	{-2.2, 1.25,  4.55, 1.3},
	{-0.6, 1.25,  4.55, 1.3},
	{ 1.0, 1.25,  4.55, 1.3},
	
	{-2.2, 1.25,  2.90, 1.3},
	{-0.6, 1.25,  2.90, 1.3},
	{ 1.0, 1.25,  2.90, 1.3},
	
	{-2.2, 1.25,  1.30, 1.3},
	{-0.6, 1.25,  1.30, 1.3},
	{ 1.0, 1.25,  1.30, 1.3},
	
	{-2.2, 2, -0.30, 1.6},
	{ 0.3, 2, -0.30, 1.6}
}


surface.CreateFont("Keypad Key", {
    font   = "Trebuchet MS";
    size   = 18;
    weight = 700
})
surface.CreateFont("Keypad Input", {
    font   = "Lucida Console";
    size   = 34;
})
surface.CreateFont("Keypad Message", {
    font   = "Lucida Console";
    size   = 19;
    weight = 600
})

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

surface.SetFont('Keypad Input');
local input_width, input_height = surface.GetTextSize('*');

local button_cutoff = 90 ^ 2;
local visual_cutoff = 750 ^ 2;

ENT.CurrentKey = 11;
ENT.NextCrackNum = 0;

function ENT:Think()
	if (self.dt.Cracking) then
		local cn = CurTime();
		if (cn < self.NextCrackNum) then
			return;
		end
		self.NextCrackNum = cn + 0.05;
		self.CurrentKey = math.random(1, 9);
		return;
	end
	self.CurrentKey = nil;
	local tr = LocalPlayer():GetEyeTrace();
	if ( tr.Entity ~= self or tr.StartPos:DistToSqr(tr.HitPos) > button_cutoff ) then
		return;
	end
	local pos = self:WorldToLocal(tr.HitPos);
	for i, btn in ipairs(KeyPos) do
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

local secnoise = surface.GetTextureID('effects/tvscreen_noise001a');
local background = Material('keypad/background.png');
function ENT:Draw()
	
	self:DrawModel()
	
	if (LocalPlayer():GetShootPos():DistToSqr(self:GetPos()) > visual_cutoff) then
		return;
	end
	
	local pos = self:GetPos() + (self:GetForward() * 1.02) + (self:GetRight() * 2.75) + (self:GetUp() * 5.25);
	local ang = self:GetAngles();
	
	ang:RotateAroundAxis(ang:Right(), -90);
	ang:RotateAroundAxis(ang:Up(),     90);
	
	cam.Start3D2D(pos, ang, 0.05)

		surface.SetMaterial(background);
		surface.SetDrawColor(color_white);
		surface.DrawTexturedRect(0, 0, 110, 210);
		
		if (self.dt.Cracking) then
			surface.SetTexture(secnoise);
			local scroll = CurTime() - math.floor(CurTime());
			surface.DrawTexturedRectUV(9, 9, 92, 51, 0, scroll, 0.3, scroll + 1)
		end

		surface.SetFont('Keypad Key');
		surface.SetTextColor(color_black);
		for i, data in pairs(keys) do
			if (self.CurrentKey == i) then
				if (i == 10) then
					surface.SetDrawColor(255, 0, 0);
				elseif (i == 11) then
					surface.SetDrawColor(0, 255, 0);
				else
					surface.SetDrawColor(255, 255, 255)
				end
				surface.DrawRect(data[4], data[5], data[6], data[7]);
			end
			surface.SetTextPos(data[1], data[2]);
			surface.DrawText(data[3]);
		end
		
		if (self.dt.ShowAccess) then
			local access = self.dt.Access;
			surface.SetFont('Keypad Message');
			surface.SetTextPos(19, 16);
			surface.SetTextColor( access and access_colour or denied_colour );
			surface.DrawText('ACCESS');
			if (access) then
				surface.SetTextPos(13, 35);
				surface.DrawText('GRANTED');
			else
				surface.SetTextPos(19, 35);
				surface.DrawText('DENIED');
			end
		else
			local pass = self.dt.Password;
			if (pass > 0) then
				surface.SetFont('Keypad Input');
				surface.SetTextColor(color_white);
				if (self.dt.Secure) then
					surface.SetTextPos(15, 24);
					surface.DrawText(string.rep("*", string.len(pass)));
				else
					surface.SetTextPos(15, 20);
					surface.DrawText(pass);
				end
			end
		end
	cam.End3D2D()
end
