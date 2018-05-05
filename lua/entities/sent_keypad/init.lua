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

local maxes = {
    rep_length      = 20;
    initial_delay   = 10;
    rep_length      = 10;
    repetitions     = 5;
};
-- Old style
local inverse_lookup = {
	['length1']     = 'access_rep_length';
	['keygroup1']   = 'access_numpad_key';
	['delay1']      = 'access_rep_delay';
	['initdelay1']  = 'access_initial_delay';
	['repeats1']    = 'access_repetitions';
	['toggle1']     = 'access_wire_toggle';
	['valueon1']    = 'access_wire_value_on';
	['valueoff1']   = 'access_wire_value_off';
	['length2']     = 'denied_rep_length';
	['keygroup2']   = 'denied_numpad_key';
	['delay2']      = 'denied_rep_delay';
	['initdelay2']  = 'denied_initial_delay';
	['repeats2']    = 'denied_repetitions';
	['toggle2']     = 'denied_wire_toggle';
	['valueon2']    = 'denied_wire_value_on';
	['valueoff2']   = 'denied_wire_value_off';
	['secure']      = 'secure';
	['Pass']        = 'password';
};
function ENT:KeyValue(key, value)
    -- Support the old style keypad KVs too
    if (inverse_lookup[key]) then
        key = inverse_lookup[key];
    end

    BaseClass.KeyValue(self, key, value);

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
        self.kvs[subcat][key] = value;
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
    end
    self.kvs[key] = value;
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

--[[ Duplicashion ]]--
if (not ConVarExists("sbox_maxkeypads")) then
    CreateConVar("sbox_maxkeypads", 10);
end

local funcargs = {
    "length1", "keygroup1", "delay1", "initdelay1", "repeats1", "toggle1", "valueon1", "valueoff1",
    "length2", "keygroup2", "delay2", "initdelay2", "repeats2", "toggle2", "valueon2", "valueoff2",
    "secure", "Pass"
}
-- Backwards compatibility
function MakeKeypad(ply, _, angles, pos, _, _, ...)
    local data = {
        Pos = pos,
        Angle = angles,
        Class = 'sent_keypad',
    };
    local arg = {...};
    for index, key in pairs(funcargs) do
        data[key] = arg[index];
    end
    return duplicator.CreateEntityFromTable(ply, data);
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
        for key, value in pairs(data.kvs) do
            if (type(value) == 'table') then
                for subkey, value in pairs(value) do
                    value = tostring(value);
                    keypad:SetKeyValue(key .. '_' .. subkey, value);
                end
            else
                value = tostring(value);
                keypad:SetKeyValue(key, value);
            end
        end
    else
        for oldkey, newkey in pairs(inverse_lookup) do
            local value = data[oldkey];
            if (value) then
                value = tostring(value);
                keypad:SetKeyValue(newkey, value);
            end
        end
    end
    return keypad;
end

duplicator.RegisterEntityClass('sent_keypad', do_dupe, "Data");
