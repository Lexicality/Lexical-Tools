--[[
	Keypads - lua/weapons/gmod_tool/stools/keypad.lua
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

TOOL.Category		= "Lexical Tools"
TOOL.Name			= "Keypad v2"

local kvs = {
	password = 0;
	secure   = 0;

	access_numpad_key       = -1;
	access_initial_delay    = 0;
	access_repetitions      = 1;

	access_rep_delay        = 0;
	access_rep_length       = 0.1;

	access_wire_value_on    = 1;
	access_wire_value_off   = 0;
	access_wire_toggle      = 0;

	denied_numpad_key       = -1;
	denied_initial_delay    = 0;
	denied_repetitions      = 1;

	denied_rep_delay        = 0;
	denied_rep_length       = 0.1;

	denied_wire_value_on    = 1;
	denied_wire_value_off   = 0;
	denied_wire_toggle      = 0;
}

for key, default in pairs(kvs) do
    TOOL.ClientConVar[key] = default;
end
TOOL.ClientConVar["freeze"] = 1;
TOOL.ClientConVar["weld"] = 0;

cleanup.Register("keypads")

if (CLIENT) then
	language.Add("tool.keypad.name", "Keypad v2" )
	language.Add("tool.keypad.desc", "Secure your contraptions with a password")
	language.Add("tool.keypad.0",    "Left click to spawn a Keypad. Right click to update an existing one");

	language.Add("Undone_Keypad",   "Undone Keypad" )
	language.Add("Cleanup_keypads", "Keypads" )
	language.Add("Cleaned_keypads", "Cleaned up all keypads" )

	language.Add("SBoxLimit_keypads", "You've hit the keypad limit!")
end

function TOOL:CheckSettings()
    local ply = self:GetOwner();
    -- Check they haven't done something silly with the password
    local password = self:GetClientNumber('password');
    if (not password or password < 1 or password > 9999 or string.find(tostring(password), '0')) then
        ply:ChatPrint("Invalid keypad password!");
        return false;
    end
    -- Make sure all the convars are numbers
    for key in pairs(kvs) do
        local num = self:GetClientNumber(key);
        if (not num) then
            ply:ChatPrint("Convar " .. key .. " value '" .. self:GetClientInfo(key) .. "' isn't a number! What did you do?");
            return false;
        end
    end
    -- Some people are silly
    local k1, k2 = self:GetClientNumber('access_numpad_key'), self:GetClientNumber('denied_numpad_key');
    if (k1 and k2 and k1 == k2 and k1 > 0) then
        ply:ChatPrint("Your Access key is the same as your Denied key!");
        return false;
    end
    return true;
end

function TOOL:LeftClick(tr)
    if (IsValid(tr.Entity) and tr.Entity:IsPlayer()) then
        return false;
    elseif (CLIENT) then
        return true;
    elseif (not self:CheckSettings()) then
        return false;
    end
    local kv = {}
    for key, def in pairs(kvs) do
        local num = self:GetClientNumber(key);
        if (num and num ~= def) then
            kv[key] = num;
        end
    end
    local owner = self:GetOwner();
    local ent = duplicator.CreateEntityFromTable(owner, {
        Pos = tr.HitPos + tr.HitNormal;
        Angle = tr.HitNormal:Angle();
        kvs = kv;
        Class = 'sent_keypad';
    });
    if (not IsValid(ent)) then
        return false;
    end
    DoPropSpawnedEffect(ent);

    if (tobool(self:GetClientNumber('freeze'))) then
        ent:GetPhysicsObject():EnableMotion(false);
    end
    local weld;
    if (tobool(self:GetClientNumber('weld')) and tr.Hit) then
        local target = tr.Entity;
        weld = constraint.Weld(ent, target, 0, tr.PhysicsBone);
        if (not tr.HitWorld) then
            target:DeleteOnRemove(ent);
            target:DeleteOnRemove(weld);
        end
        ent:DeleteOnRemove(weld);
    end

    undo.Create('Keypad');
    undo.SetPlayer(owner);
    undo.AddEntity(ent);
    undo.AddEntity(weld);
    undo.Finish();

    owner:AddCleanup("keypads", ent);

    return true;
end

function TOOL:RightClick(tr)
    local ent = tr.Entity;
    if (not (IsValid(ent) and ent:GetClass() == 'sent_keypad')) then
        return false;
    elseif (CLIENT) then
        return true;
    elseif (not self:CheckSettings()) then
        return false;
    end

    for key in pairs(kvs) do
        ent:SetKeyValue(key, self:GetClientNumber(key));
    end

    return true;
end

if (SERVER) then return; end

local function c(name)
    return "keypad_" .. name;
end

local function subpanel(CPanel, kind, data)
    local function k(name)
        return c(kind .. '_' .. name);
    end
    local CPanel = CPanel:AddControl("CPanel", data);
    CPanel:AddControl("Numpad", {
        Label   = "Key",
        Command = k'numpad_key',
    });
    CPanel:NumSlider("Key Hold Length", k'rep_length', 0.1, 20, 1);
    if (WireLib) then
        CPanel:TextEntry("Wire Output Value", k'wire_value_on');
    end
    do
        local CPanel = CPanel:AddControl("CPanel", {
            Label       = "Advanced",
            Closed      = true,
        });
        if (WireLib) then
            CPanel:TextEntry("Wire Default Value", k'wire_value_off');
            CPanel:CheckBox("Toggle Wire Output", k'wire_toggle');
        end
        CPanel:NumSlider("Initial Delay", k'initial_delay', 0, 10, 1);
        CPanel:NumSlider("Repititions", k'repetitions', 1, 5, 0);
        CPanel:NumSlider("Delay between repititions", k'rep_length', 0, 10, 1);
    end
end

function TOOL.BuildCPanel( CPanel )
    CPanel:TextEntry("Password",        c'password');
    CPanel:CheckBox("Secure Mode",      c'secure');
    CPanel:CheckBox("Weld Keypad",      c'weld');
    CPanel:CheckBox("Freeze Keypad",    c'freeze');

    subpanel(CPanel, 'access', {
        Label       = "Access Granted",
    });
    subpanel(CPanel, 'denied', {
        Label       = "Access Denied",
        Closed      = true
    });
end

local PANEL = {}

function PANEL:ControlValues(data)
    if (data.label) then
        self:SetLabel(data.label);
    end
    if (data.closed) then
        self:SetExpanded(false);
    end
end

vgui.Register("cpanel", PANEL, "ControlPanel");
