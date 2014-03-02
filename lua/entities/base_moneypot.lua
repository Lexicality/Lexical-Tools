--[[
    Base Moneypot
    Copyright (c) 2010-2014 Lex Robinson
    This code is freely available under the MIT License
--]]

AddCSLuaFile();

ENT.Type            = "anim"
ENT.PrintName       = "Money Pot"
ENT.Author          = "Lexi"
ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.IsMoneyPot      = true;

local BaseClass;
if (WireLib) then
    BaseClass = "base_wire_entity"
else
    BaseClass = "base_gmodentity"
end
DEFINE_BASECLASS(BaseClass);

if (CLIENT) then return; end

--------------------------------------
--                                  --
--   Overridables for customisation --
--                                  --
--------------------------------------

function ENT:IsMoneyEntity(ent)
    return false;
end

function ENT:SpawnMoneyEntity(amount)
    return NULL;
end

function ENT:GetNumMoneyEntities()
    return math.huge;
end

function ENT:InvalidateMoneyEntity(ent)
    ent._InvalidMoney = true;
end

function ENT:IsMoneyEntityInvalid(ent)
    return ent._InvalidMoney == true;
end

--------------------------------------
--                                  --
--              / END               --
--                                  --
--------------------------------------

function ENT:Initialize()
    self:SetModel("models/props_lab/powerbox02b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:UpdateOverlay()
    if (WireLib) then
        WireLib.CreateSpecialInputs(self, {
            "SpawnAll",
            "SpawnAmount"
        });
        WireLib.CreateSpecialOutputs(self, {
            "StoredAmount",
            "LastAmount",
            "Updated"
        });
    end
    local phys = self:GetPhysicsObject()
    if (not phys:IsValid()) then
        local mdl = self:GetModel()
        self:Remove();
        error("Entity of type " .. self.ClassName .. " created without a physobj! (Model: " .. mdl .. ")");
    end
    phys:Wake()
end

function ENT:Use(activator)
    self:DelayedSpawn(self:GetDTInt(0));
end

function ENT:UpdateWireOutputs(amount)
    if (not Wire_TriggerOutput) then return; end
    Wire_TriggerOutput(self, "StoredAmount", self:GetDTInt(0));
    Wire_TriggerOutput(self, "LastAmount", amount);
    Wire_TriggerOutput(self, "Updated", 1);
    Wire_TriggerOutput(self, "Updated", 0);
end

function ENT:StartTouch(ent)
    if (IsValid(ent) and self:IsMoneyEntity(ent) and not self:IsMoneyEntityInvalid(ent) and (ent.MoneyPotPause or 0) < CurTime()) then
        self:InvalidateMoneyEntity(ent);
        ent.MoneyPotPause = CurTime() + 100
        local amt = ent.dt.amount;
        ent:Remove();
        self:SetDTInt(0, self:GetDTInt(0) + amt);
        self:UpdateOverlay();
        self:UpdateWireOutputs(amt);
    end
end

local spos = Vector(0, 0, 17);
function ENT:SpawnAmount(amount)
    amount = math.Clamp(amount, 0, self:GetDTInt(0));
    if (amount == 0) then return; end
    -- Prevent people spawning too many
    if (self:GetNumMoneyEntities() >= 50) then return; end
    
    local cash = self:SpawnMoneyEntity(amount);
    if (cash == NULL) then
        error("Moneypot (" .. self.ClassName .. ") unable to create cash entity!");
    end
    cash:SetPos(self:LocalToWorld(spos));
    cash:Spawn();
    cash:Activate();
    cash.MoneyPotPause = CurTime() + 5;
    self:SetDTInt(0, self:GetDTInt(0) - amount);
    self:UpdateWireOutputs(-amount);
    self:UpdateOverlay()
end

-- For calling from lua (ie so /givemoney can give direct to it)
function ENT:AddMoney(amount)
    self:SetDTInt(0, self:GetDTInt(0) + amount);
    self:UpdateOverlay();
    self:UpdateWireOutputs(amount);
end

function ENT:UpdateOverlay()
    self:SetOverlayText("- Money Pot -\nAmount: $" .. self:GetDTInt(0));
end

function ENT:DelayedSpawn(amount)
    amount = math.Clamp(amount, 0, self:GetDTInt(0));
    if (amount == 0) then return; end
    if (self.DoSpawn) then
        self.DoSpawn = self.DoSpawn + amount;
    else
        self.DoSpawn = amount;
    end
    self.SpawnTime = CurTime() + 1;
end

-- From Moneyprinter
ENT.DoSpawn = false;
ENT.SpawnTime = 0;
function ENT:Think()
    BaseClass.Think(self);
    if (not self.DoSpawn) then
        return;
    end
    local ctime = CurTime();
    if (self.SpawnTime < ctime) then
        self:SpawnAmount(self.DoSpawn);
        self.DoSpawn = false;
        return;
    end

    local effectdata = EffectData();
    effectdata:SetOrigin(self:GetPos());
    effectdata:SetMagnitude(1);
    effectdata:SetScale(1);
    effectdata:SetRadius(2);
    util.Effect("Sparks", effectdata);
end

function ENT:OnRemove()
    self:SpawnAmount(self:GetDTInt(0))
    BaseClass.OnRemove(self);
end

function ENT:TriggerInput(key, value)
    if (key == "SpawnAll" and value ~= 0) then
        self:Use();
    elseif (key == "SpawnAmount"  and value ~= 0) then
        self:DelayedSpawn(value);
    end
end
