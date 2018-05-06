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

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.PrecacheSound("buttons/button14.wav")
util.PrecacheSound("buttons/button9.wav")
util.PrecacheSound("buttons/button8.wav")
util.PrecacheSound("buttons/button15.wav")

ENT.WireDebugName = "Keypad"

function ENT:Initialize()
    self:SetModel("models/props_lab/keypad.mdl");
    self:PhysicsInit(SOLID_VPHYSICS);
    self:SetMoveType(MOVETYPE_VPHYSICS);
    self:SetSolid(SOLID_VPHYSICS);
    self:SetUseType(SIMPLE_USE);
    self:GetValidPhysicsObject():Wake();

    -- Defaults
    self.kvs = {
        password = 0;
        secure = false;
        access = {
            numpad_key      = nil,
            initial_delay   = 0,
            repetitions     = 1,

            rep_delay       = 0;
            rep_length      = 0.1,

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

            wire_value_on   = 1,
            wire_value_off  = 0,
            wire_toggle     = false,
        },
    };
    self._WireToggleStates = { Valid = false, Invalid = false };
    self._Password = 0;

    self:CreateWireOutputs({
        {
            Name = "Valid";
            Desc = "Triggered when the right code is entered";
        };
        {
            Name = "Invalid";
            Desc = "Triggered when the wrong code is entered";
        };
    })
end

function ENT:SetPassword(pass)
    self:SetKeyValue('password', pass);
end

function ENT:CheckPassword(pass)
    return self.kvs.password == (tonumber(pass) or 0);
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
    rep_length      = 10;
    repetitions     = 5;
};
function ENT:KeyValue(key, value)
    BaseClass.KeyValue(self, key, value);

    if (not allowed_kvs[key]) then return; end

    local subcat = string.sub(key, 1, 6);
    if (subcat == 'access' or subcat == 'denied') then
        key = string.sub(key, 8);

        if (key == 'wire_toggle') then
            value = tobool(value);
        else
            value = tonumber(value) or -1;
            if (key == 'numpad_key') then
                if (value < 0) then
                    value = nil;
                end
            elseif (key == 'rep_length' and value < 0.1) then
                value = 0.1
            elseif (key == 'repetitions') then
                value = math.floor(value);
                if (value < 1) then
                    value = 1;
                end
            elseif (value < 0) then
                value = 0;
            end
        end
        if (maxes[key]) then
            value = math.min(value, maxes[key]);
        end

        if (self.kvs[subcat][key] ~= value) then
            self.kvs[subcat][key] = value;
            self:_UpdateLegacyFromKVs();
        end

        if (key == "wire_value_off" and WireLib) then
            local output = subcat == 'access' and "Valid" or "Invalid"
            if (not self._WireToggleStates[output]) then
                WireLib.TriggerOutput(self, output, value);
            end
        end
        return;
    elseif (key == 'secure') then
        value = tobool(value);
    elseif (key == 'password') then
        value = tonumber(value) or 0;
        value = math.floor(tonumber(value) or 0);
        if (value < 0 or value > 9999) then
            value = 0;
        end
    end

    if (self.kvs[key] ~= value) then
        self.kvs[key] = value;
        self:_UpdateLegacyFromKVs();
    end
end

ENT.ResetSound = "buttons/button14.wav";
ENT.RightSound = "buttons/button9.wav";
ENT.WrongSound = "buttons/button8.wav";
ENT.PressSound = "buttons/button15.wav"

local function ResetKeypad(self)
    if (not IsValid(self)) then return; end
    self._Password = 0;
    self.dt.PasswordDisplay = 0;
    self.dt.Access = false;
    self.dt.ShowAccess = false;
end

function ENT:KeypadInput(input)
    if (input == 'reset') then
        self:EmitSound(self.ResetSound);
        ResetKeypad(self);
    elseif (input == 'accept') then
        local valid = self:CheckPassword(self._Password)
        self:TriggerKeypad(valid);
    elseif (not self.dt.ShowAccess) then -- You can't modify the keypad while it's doin stuff
        local newnum = self._Password * 10 + (tonumber(input) or 0)
        if (newnum > 9999) then return; end
        self._Password = newnum;
        if (self.dt.Secure) then
            self.dt.PasswordDisplay = self.dt.PasswordDisplay * 10 + 1
        else
            self.dt.PasswordDisplay = self._Password;
        end
        self:EmitSound(self.PressSound);
    end
end

--[[ Keypad Triggerin Locals ]]--
do
    local function GetPlayer(self)
        local ply = self:GetPlayer();
        return IsValid(ply) and ply or false;
    end

    local function numpad_activate(self, kvs)
        if (not IsValid(self)) then return; end
        local ply = GetPlayer(self);
        if (ply) then
            numpad.Activate(ply, kvs.numpad_key, true);
        end
    end

    local function numpad_deactivate(self, kvs)
        if (not IsValid(self)) then return; end
        local ply = GetPlayer(self);
        if (ply) then
            numpad.Deactivate(ply, kvs.numpad_key, true);
        end
    end

    local function GetWireOutput(valid)
        return valid and "Valid" or "Invalid";
    end

    local function wire_on(self, kvs, valid)
        if (not IsValid(self)) then return; end
        WireLib.TriggerOutput(self, GetWireOutput(valid), kvs.wire_value_on);
    end

    local function wire_off(self, kvs, valid)
        if (not IsValid(self)) then return; end
        WireLib.TriggerOutput(self, GetWireOutput(valid), kvs.wire_value_off);
    end

    local function wire_toggle(self, kvs, valid)
        if (not IsValid(self)) then return; end
        local name = GetWireOutput(valid);
        local state = not self._WireToggleStates[name];
        print("WIRE TOGGLE", name, state);
        if (state) then
            wire_on(self, kvs, valid);
        else
            wire_off(self, kvs, valid);
        end
        self._WireToggleStates[name] = state;
    end

    function ENT:TriggerKeypad(access)
        -- Look & Feel
        self:EmitSound(access and self.RightSound or self.WrongSound);
        self.dt.Access = access;
        self.dt.ShowAccess = true;
        -- TODO: Uhhhh
        timer.Simple(2, function() ResetKeypad(self) end);
        -- Triggering
        local kvs;
        if (access) then
            kvs = self.kvs.access;
        else
            kvs = self.kvs.denied;
        end
        local numpad_key = kvs.numpad_key;
        local delay = kvs.initial_delay;
        local rep_delay  = kvs.rep_delay;
        local rep_length = kvs.rep_length;
        for rep = 0, kvs.repetitions - 1 do
            if (numpad_key) then
                timer.Simple(delay,              function() numpad_activate(self, kvs)   end);
                timer.Simple(delay + rep_length, function() numpad_deactivate(self, kvs) end);
            end
            if (WireLib) then
                if (kvs.wire_toggle) then
                    local delay = kvs.initial_delay + rep_delay * rep;
                    timer.Simple(delay,              function() wire_toggle(self, kvs, access) end);
                else
                    timer.Simple(delay,              function() wire_on(self, kvs, access)  end);
                    timer.Simple(delay + rep_length, function() wire_off(self, kvs, access) end);
                end
            end
            delay = delay + rep_length + rep_delay;
        end
    end
end


ENT.NextCrackNum = 0;
function ENT:Think()
    if (not self.dt.Cracking) then
        return;
    end
    local cn = CurTime();
    if (cn < self.NextCrackNum) then
        return;
    end
    self.NextCrackNum = cn + 0.05;
    self:EmitSound(self.PressSound);
end

util.AddNetworkString('gmod_keypad');
net.Receive('gmod_keypad', function(_, ply)
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

    -- Don't allow input while being cracked
    if (tr.Entity.dt.Cracking) then
        return;
    end

    tr.Entity:KeypadInput(cmd);
end);

function ENT:Use(activator)
    if (not (IsValid(activator) and activator:IsPlayer())) then
        return;
    end
    -- Don't allow input while being cracked
    if (self.dt.Cracking) then
        return;
    end
    local tr = activator:GetEyeTrace();
    local pos = self:WorldToLocal(tr.HitPos);
    for i, btn in ipairs(self.KeyPositions) do
        local x = (pos.y - btn[1]) / btn[2];
        local y = 1 - (pos.z + btn[3]) / btn[4];
        if (x >= 0 and x <= 1 and y >= 0 and y <= 1) then
            local cmd = i;
            if (i == 10) then
                cmd = 'reset';
            elseif (i == 11) then
                cmd = 'accept';
            end
            self:KeypadInput(cmd);
            return;
        end
    end
end

if (not ConVarExists("sbox_maxkeypads")) then
    CreateConVar("sbox_maxkeypads", 10);
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

        keypad._Restoring = true
        for key, value in pairs(data.kvs) do
            if (type(value) == 'table') then
                for subkey, value in pairs(value) do
                    setkv(key .. '_' .. subkey, value);
                end
            else
                setkv(key, value);
            end
        end
        keypad._Restoring = false

        -- The old style data isn't compatible with the new style wire outputs.
        if (data.EntityMods and data.EntityMods['keypad_password_passthrough']) then
            data.EntityMods['keypad_password_passthrough']['OutputOn'] = nil;
            data.EntityMods['keypad_password_passthrough']['OutputOff'] = nil;
        end
    end

    return keypad;
end

duplicator.RegisterEntityClass('keypad', do_dupe, "Data");

local function do_dupe_alias(ply, data)
    data.Class = "keypad";
    return do_dupe(ply, data);
end
local function setup_alias(name)
    scripted_ents.Alias(name, "keypad");
    duplicator.RegisterEntityClass(name, do_dupe_alias, "Data");
end

-- ALL OF THE BACKWARDS COMPATIBILITY
setup_alias('sent_keypad');
setup_alias('sent_keypad_wire');
setup_alias('keypad_wire');

ENT.Process = ENT.TriggerKeypad;
ENT.SetKeypadOwner = ENT.SetPlayer;
ENT.GetKeypadOwner = ENT.GetPlayer;

local w2m = {
    Password = 'password',
    Secure = 'secure',

    KeyGranted = 'access_numpad_key',
    InitDelayGranted = 'access_initial_delay',
    RepeatsGranted = 'access_repetitions',
    DelayGranted = 'access_rep_delay',
    LengthGranted = 'access_rep_length',

    KeyDenied = 'denied_numpad_key',
    InitDelayDenied = 'denied_initial_delay',
    RepeatsDenied = 'denied_repetitions',
    DelayDenied = 'denied_rep_delay',
    LengthDenied = 'denied_rep_length',
}

duplicator.RegisterEntityModifier("keypad_password_passthrough", function(ply, ent, data) ent:SetData(data) end)

ENT._Restoring = false;
function ENT:SetData(data)
    self._Restoring = true;
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
        self:SetKeyValue("denied_wire_value_on", data["OutputOn"])
    end
    self._Restoring = false;
    self:_UpdateLegacyFromKVs();
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

function ENT:_UpdateLegacyFromKVs()
    if (self._Restoring) then return; end
    duplicator.StoreEntityModifier(self, "keypad_password_passthrough", self:GetData())
end

-- I don't think these are strictly necessary but whatever
function ENT:PreEntityCopy()
    self.KeypadData = self:GetData();
end

function ENT:PostEntityCopy()
    self.KeypadData = nil;
end

function ENT:PostEntityPaste(ply, ent, all_ents)
    -- Update the entity modifier to the combination of everything that's just happened
    self:_UpdateLegacyFromKVs();
end
