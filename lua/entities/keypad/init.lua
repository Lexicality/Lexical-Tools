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
--]]
DEFINE_BASECLASS "base_lexentity";

AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
include("shared.lua");

resource.AddFile("materials/keypad/background.png");

CreateConVar("sbox_maxkeypads", 10, FCVAR_ARCHIVE);
local cvar_min_length = CreateConVar("keypad_min_length", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "The minimum time keypads must remain on for");
local cvar_min_recharge = CreateConVar("keypad_min_recharge", 2, FCVAR_ARCHIVE, "The minimum time between keypad code attempts");
-- Potentially a user could lock out a keypad for two and a half minutes, so don't let them
local cvar_max_recharge = CreateConVar("keypad_max_recharge", 30, FCVAR_ARCHIVE, "The maximum time between keypad code attempts (to avoid long timer abuse)");

util.PrecacheSound("buttons/button14.wav")
util.PrecacheSound("buttons/button9.wav")
util.PrecacheSound("buttons/button8.wav")
util.PrecacheSound("buttons/button15.wav")

ENT.WireDebugName = "Keypad"

function ENT:Initialize()
	BaseClass.Initialize(self);
	self:SetModel("models/props_lab/keypad.mdl");
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);
	self:SetUseType(SIMPLE_USE);
	self:GetValidPhysicsObject():Wake();

	-- Defaults
	self.kvs = {
		password = "";
		secure = false;
		access = {
			numpad_key      = nil,
			initial_delay   = 0,
			repetitions     = 1,

			rep_delay       = 0;
			rep_length      = 0.1,

			wire_name = "Access Granted",
			wire_value_on   = 1,
			wire_value_off  = 0,
			wire_toggle     = false,
		},
		denied = {
			numpad_key      = nil,
			initial_delay   = 0,
			repetitions     = 1,

			rep_delay       = 0;
			rep_length      = 0.1,

			wire_name = "Access Denied",
			wire_value_on   = 1,
			wire_value_off  = 0,
			wire_toggle     = false,
		},
	};
	self._WireToggleStates = { [self.kvs.access.wire_name] = false, [self.kvs.denied.wire_name] = false };
	self._Password = "";

	self:CreateWireOutputs({
		{
			Name = self.kvs.access.wire_name;
			Desc = "Triggered when the right code is entered";
		};
		{
			Name = self.kvs.denied.wire_name;
			Desc = "Triggered when the wrong code is entered";
		};
	})
end

function ENT:SetPassword(pass)
	self:SetKeyValue("password", pass);
end

function ENT:CheckPassword(pass)
	if (pass == "") then
		return false;
	end

	return self.kvs.password == pass;
end

local allowed_kvs = {
	password              = true,
	secure                = true,
	access_numpad_key     = true,
	access_initial_delay  = true,
	access_repetitions    = true,
	access_rep_delay      = true,
	access_rep_length     = true,
	access_wire_value_on  = true,
	access_wire_value_off = true,
	access_wire_toggle    = true,
	denied_numpad_key     = true,
	denied_initial_delay  = true,
	denied_repetitions    = true,
	denied_rep_delay      = true,
	denied_rep_length     = true,
	denied_wire_value_on  = true,
	denied_wire_value_off = true,
	denied_wire_toggle    = true,
}
local maxes = {
	rep_length      = 20;
	initial_delay   = 10;
	rep_delay       = 10;
	repetitions     = 5;
};
function ENT:KeyValue(key, value)
	BaseClass.KeyValue(self, key, value);

	if (not allowed_kvs[key]) then return; end

	local subcat = string.sub(key, 1, 6);
	if (subcat == "access" or subcat == "denied") then
		key = string.sub(key, 8);

		if (key == "wire_toggle") then
			value = tobool(value);
		else
			value = tonumber(value) or -1;
			if (key == "numpad_key") then
				if (value < 0) then
					value = nil;
				end
			elseif (key == "repetitions") then
				value = math.floor(value);
				if (value < 1) then
					value = 1;
				end
			elseif (not (key == "wire_value_on" or key == "wire_value_off")) then
				if (value < 0) then
					value = 0;
				end
			end
		end

		if (maxes[key]) then
			value = math.min(value, maxes[key]);
		end

		self.kvs[subcat][key] = value;

		if (key == "wire_value_on" or key == "wire_value_off") then
			self:HandleWireValueChange(self.kvs[subcat]);
		end

		return;
	elseif (key == "secure") then
		value = tobool(value);
	elseif (key == "password") then
		if (value ~= "" and not self:IsValidKeypadPassword(value)) then
			error(string.format("Invalid keypad password %q", value));
		end
	end

	self.kvs[key] = value;
end

ENT.ResetSound = "buttons/button14.wav";
ENT.RightSound = "buttons/button9.wav";
ENT.WrongSound = "buttons/button8.wav";
ENT.PressSound = "buttons/button15.wav"

local function ResetKeypad(self)
	if (not IsValid(self)) then return; end
	self._Password = "";
	self:SetPasswordDisplay("");
	self:SetStatus(self.STATUSES.Normal);
end

-- Possibly people may wish to override this in a subclass
function ENT:IsValidKeypadPassword(password)
	local matches, len = string.find(password, "^[1-9]+$");
	return matches and len <= 8;
end

function ENT:IsInteractive()
	return self:GetStatus() == self.STATUSES.Normal and not self:IsBeingCracked()
end

function ENT:KeypadInput(input)
	-- Prevent the keypad being messed with when it's doing stuff
	if (not self:IsInteractive()) then
		return;
	end

	if (input == "reset") then
		self:EmitSound(self.ResetSound);
		ResetKeypad(self);
		return;
	elseif (input == "accept") then
		local valid = self:CheckPassword(self._Password)
		self:TriggerKeypad(valid);
		return;
	end

	if (not tonumber(input) or #input ~= 1) then
		-- Sanity check
		return;
	end

	local newPassword = self._Password .. input;
	if (not self:IsValidKeypadPassword(newPassword)) then
		return;
	end

	-- Beep
	self:EmitSound(self.PressSound);

	self._Password = newPassword;

	if (self:IsSecure()) then
		self:SetPasswordDisplay(string.rep('*', #self._Password));
	else
		self:SetPasswordDisplay(self._Password);
	end
end

--[[ Keypad Triggerin Locals ]]--
do
	local function set_numpad_state(ent, kvs, state)
		if (not IsValid(ent)) then return; end
		local ply = ent:GetPlayer();
		if (not IsValid(ply)) then return; end
		local func = state and numpad.Activate or numpad.Deactivate;
		func(ply, kvs.numpad_key, true);
	end

	local function set_wire_state(ent, kvs, state)
		if (not IsValid(ent)) then return; end

		local value = state and kvs.wire_value_on or kvs.wire_value_off;

		ent:TriggerWireOutput(kvs.wire_name, value)
	end

	local function toggle_wire_state(ent, kvs)
		if (not IsValid(ent)) then return; end

		local state = ent._WireToggleStates[kvs.wire_name];
		state = not state;
		ent._WireToggleStates[kvs.wire_name] = state;

		set_wire_state(ent, kvs, state);
	end

	local function on_off(ent, kvs, func, delay, length)
		timer.Simple(delay,          function() func(ent, kvs, true);  end)
		timer.Simple(delay + length, function() func(ent, kvs, false); end)
	end

	function ENT:HandleWireValueChange(kvs)
		if (not WireLib) then return; end
		-- Don't do anything if we're mid-play
		if (self:GetStatus() ~= self.STATUSES.Normal) then return; end

		local state = false;
		if (kvs.wire_toggle) then
			state = self._WireToggleStates[kvs.wire_name];
		end
		set_wire_state(self, kvs, state);
	end

	function ENT:TriggerKeypad(access)
		-- Prevent the keypad being messed with when it's doing stuff
		if (not self:IsInteractive()) then
			return;
		end

		local kvs;
		if (access) then
			self:EmitSound(self.RightSound);
			self:SetStatus(self.STATUSES.AccessGranted);
			kvs = self.kvs.access;
		else
			self:EmitSound(self.WrongSound);
			self:SetStatus(self.STATUSES.AccessDenied);
			kvs = self.kvs.denied;
		end

		local numpad_key = kvs.numpad_key;

		-- If nothing is going to happen, do nothing.
		if (not numpad_key and not self:IsWireOutputConnected(kvs.wire_name)) then
			timer.Simple(cvar_min_recharge:GetFloat(), function() ResetKeypad(self) end)
			return;
		end

		local delay      = kvs.initial_delay;
		local num_reps   = kvs.repetitions;
		local rep_delay  = kvs.rep_delay;
		local rep_length = math.max(kvs.rep_length, cvar_min_length:GetFloat());

		local total_time = delay + (num_reps * rep_length) + ((num_reps - 1) * rep_delay);
		-- Show the "Access XXX" screen for quarter of a second after all effects finish
		local recharge_time = math.min(math.max(total_time + 0.25, cvar_min_recharge:GetFloat()), cvar_max_recharge:GetFloat());
		timer.Simple(recharge_time, function() ResetKeypad(self) end)

		for rep = 0, num_reps - 1 do
			if (numpad_key) then
				on_off(self, kvs, set_numpad_state, delay, rep_length)
			end
			if (WireLib) then
				if (kvs.wire_toggle) then
					local delay = kvs.initial_delay + rep_delay * rep;
					timer.Simple(delay, function() toggle_wire_state(self, kvs, access) end);
				else
					on_off(self, kvs, set_wire_state, delay, rep_length)
				end
			end
			delay = delay + rep_length + rep_delay;
		end
	end
end


ENT.NextCrackNum = 0;
function ENT:Think()
	if (BaseClass.Think) then BaseClass.Think(self); end
	if (not self:IsBeingCracked()) then
		return;
	end
	local cn = CurTime();
	if (cn < self.NextCrackNum) then
		return;
	end
	self.NextCrackNum = cn + 0.05;
	self:EmitSound(self.PressSound);
end

util.AddNetworkString("gmod_keypad");
net.Receive("gmod_keypad", function(_, ply)
	if (not IsValid(ply)) then return; end
	local tr = ply:GetEyeTrace();
	if (not (IsValid(tr.Entity) and tr.Entity.IsKeypad) or tr.StartPos:Distance(tr.HitPos) > 50) then
		return;
	end
	tr.Entity:KeypadInput(net.ReadString());
end);
local binds = {
	[KEY_PAD_1] = "1",
	[KEY_PAD_2] = "2",
	[KEY_PAD_3] = "3",
	[KEY_PAD_4] = "4",
	[KEY_PAD_5] = "5",
	[KEY_PAD_6] = "6",
	[KEY_PAD_7] = "7",
	[KEY_PAD_8] = "8",
	[KEY_PAD_9] = "9",
	[KEY_PAD_ENTER] = "accept",
	[KEY_PAD_PLUS] = "reset",
}
hook.Add("PlayerButtonDown", "Keypad Numpad Magic", function(ply, button)
	local cmd = binds[button];
	if (not cmd) then return; end

	local tr = ply:GetEyeTrace();
	if (not (IsValid(tr.Entity) and tr.Entity.IsKeypad) or tr.StartPos:Distance(tr.HitPos) > 90) then
		return;
	end

	tr.Entity:KeypadInput(cmd);
end);

function ENT:Use(activator, ...)
	if (BaseClass.Use) then BaseClass.Use(self, activator, ...); end
	if (not (IsValid(activator) and activator:IsPlayer())) then
		return;
	elseif (not self:IsInteractive()) then
		-- Don't allow input while being cracked
		return;
	end

	local tr = activator:GetEyeTrace();
	local pos = self:WorldToLocal(tr.HitPos);
	for i, btn in ipairs(self.KeyPositions) do
		local x = (pos.y - btn[1]) / btn[2];
		local y = 1 - (pos.z + btn[3]) / btn[4];
		if (x >= 0 and x <= 1 and y >= 0 and y <= 1) then
			if (i == 10) then
				cmd = "reset";
			elseif (i == 11) then
				cmd = "accept";
			else
				cmd = tostring(i);
			end
			self:KeypadInput(cmd);
			return;
		end
	end
end

local function do_dupe(ply, data)
	if (not BaseClass.CanDuplicate(ply, data)) then
		return;
	end

	local keypad = BaseClass.GenericDuplicate(ply, data);
	if (not IsValid(keypad)) then
		return keypad;
	end

	if (data.kvs) then
		local function setkv(key, value)
			if (allowed_kvs[key]) then
				keypad:SetKeyValue(key, tostring(value));
			end
		end

		for key, value in pairs(data.kvs) do
			if (type(value) == "table") then
				for subkey, value in pairs(value) do
					setkv(key .. "_" .. subkey, value);
				end
			else
				setkv(key, value);
			end
		end

		-- The old style data isn't compatible with the new style wire outputs.
		if (data.EntityMods and data.EntityMods["keypad_password_passthrough"]) then
			data.EntityMods["keypad_password_passthrough"]["OutputOn"] = nil;
			data.EntityMods["keypad_password_passthrough"]["OutputOff"] = nil;
		end
	end

	return keypad;
end

duplicator.RegisterEntityClass("keypad", do_dupe, "Data");

local function do_dupe_alias(ply, data)
	data.Class = "keypad";
	return do_dupe(ply, data);
end
local function setup_alias(name)
	scripted_ents.Alias(name, "keypad");
	duplicator.RegisterEntityClass(name, do_dupe_alias, "Data");
end

-- ALL OF THE BACKWARDS COMPATIBILITY
setup_alias("sent_keypad");
setup_alias("sent_keypad_wire");
setup_alias("keypad_wire");

ENT.Process = ENT.TriggerKeypad;
ENT.SetKeypadOwner = ENT.SetPlayer;
ENT.GetKeypadOwner = ENT.GetPlayer;

local w2m = {
	Password = "password",
	Secure = "secure",

	KeyGranted = "access_numpad_key",
	InitDelayGranted = "access_initial_delay",
	RepeatsGranted = "access_repetitions",
	DelayGranted = "access_rep_delay",
	LengthGranted = "access_rep_length",

	KeyDenied = "denied_numpad_key",
	InitDelayDenied = "denied_initial_delay",
	RepeatsDenied = "denied_repetitions",
	DelayDenied = "denied_rep_delay",
	LengthDenied = "denied_rep_length",
}

duplicator.RegisterEntityModifier("keypad_password_passthrough", function(ply, ent, data) ent:SetData(data) end)

function ENT:SetData(data)
	for key, kv in pairs(w2m) do
		if data[key] then
			self:SetKeyValue(kv, tostring(data[key]));
		end
	end
	-- :(
	if (data["OutputOn"]) then
		self:SetKeyValue("access_wire_value_on", data["OutputOn"])
		self:SetKeyValue("denied_wire_value_on", data["OutputOn"])
	end
	if (data["OutputOff"]) then
		self:SetKeyValue("access_wire_value_off", data["OutputOff"])
		self:SetKeyValue("denied_wire_value_off", data["OutputOff"])
	end
end

function ENT:GetData()
	return {
		Password = self.kvs.password,

		RepeatsGranted = self.kvs.access.repetitions,
		RepeatsDenied = self.kvs.denied.repetitions,

		LengthGranted = self.kvs.access.rep_length,
		LengthDenied = self.kvs.denied.rep_length,

		DelayGranted = self.kvs.access.rep_delay,
		DelayDenied = self.kvs.denied.rep_delay,

		InitDelayGranted = self.kvs.access.initial_delay,
		InitDelayDenied = self.kvs.denied.initial_delay,

		KeyGranted = self.kvs.access.numpad_key,
		KeyDenied = self.kvs.denied.numpad_key,

		OutputOn = self.kvs.access.wire_value_on,
		OutputOff = self.kvs.access.wire_value_off,

		Secure = self.kvs.secure,
	};
end

-- I don't think these are strictly necessary but whatever
function ENT:PreEntityCopy()
	if (BaseClass.PreEntityCopy) then BaseClass.PreEntityCopy(self); end
	self.KeypadData = self:GetData();
	duplicator.StoreEntityModifier(self, "keypad_password_passthrough", self.KeypadData);
end

function ENT:PostEntityCopy()
	if (BaseClass.PostEntityCopy) then BaseClass.PostEntityCopy(self); end
	self.KeypadData = nil;
end
