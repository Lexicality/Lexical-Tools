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

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Money");
end

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

function ENT:SpawnAll(immediate)
    local amount = self:GetMoney();
    if (immediate) then
        self:SpawnAmount(amount)
    else
        self:DelayedSpawn(amount);
    end
end

function ENT:Use(activator)
    self:SpawnAll(false);
end

function ENT:UpdateWireOutputs(amount)
    if (not Wire_TriggerOutput) then return; end
    Wire_TriggerOutput(self, "StoredAmount", self:GetMoney());
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
        self:AddMoney(amt);
    end
end

local spos = Vector(0, 0, 17);
function ENT:SpawnAmount(amount)
    amount = math.Clamp(amount, 0, self:GetMoney());
    if (amount == 0) then return; end
    -- Prevent people spawning too many
    if (self:GetNumMoneyEntities() >= 50) then return; end

    local cash = self:SpawnMoneyEntity(amount);
    if (cash == NULL) then
        error("Moneypot (" .. self.ClassName .. ") unable to create cash entity!");
    end
    -- Remove our money before the new money exists
    self:AddMoney(-amount);

    cash:SetPos(self:LocalToWorld(spos));
    cash:Spawn();
    cash:Activate();
    cash.MoneyPotPause = CurTime() + 5;
end

-- For calling from lua (ie so /givemoney can give direct to it)
function ENT:AddMoney(amount)
    self:SetMoney(self:GetMoney() + amount);
    self:UpdateOverlay();
    self:UpdateWireOutputs(amount);
end

function ENT:UpdateOverlay()
    self:SetOverlayText("- Money Pot -\nAmount: $" .. self:GetMoney());
end

function ENT:DelayedSpawn(amount)
    amount = math.Clamp(amount, 0, self:GetMoney());
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
    self:SpawnAll(true);
    BaseClass.OnRemove(self);
end

function ENT:TriggerInput(key, value)
    if (key == "SpawnAll" and value ~= 0) then
        self:SpawnAll(false);
    elseif (key == "SpawnAmount"  and value ~= 0) then
        self:DelayedSpawn(value);
    end
end
