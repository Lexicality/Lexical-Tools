--[[
	NPC Spawn Platforms V2 - lua/entities/sent_spawnplatform/init.lua
    Copyright 2009-2017 Lex Robinson

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

AddCSLuaFile("shared.lua");
include('shared.lua');

DEFINE_BASECLASS(ENT.Base);

--[[ The built in duplicator function messes with the platform too much ]]--
duplicator.RegisterEntityClass("sent_spawnplatform", function(ply, data)
	if (BaseClass.CanDuplicate(ply, data)) then
		return BaseClass.GenericDuplicate(ply, data);
	end
	return nil;
end, "Data");

-- Deal with old save data
function ENT:OnDuplicated(data)
	for key, value in pairs(data) do
		if (key:sub(1, 2) == "k_") then
			self:SetKeyValue(key:sub(3), value);
		end
	end
end

local model_active = Model("models/props_c17/streetsign004e.mdl");
local model_inactive = Model("models/props_c17/streetsign004f.mdl");
--[[
Medic:
		SpawnFlags	=	131072
		Class	=	npc_citizen
		Category	=	Humans + Resistance
		Name	=	Medic
		Weapons:
				1	=	weapon_pistol
				2	=	weapon_smg1
				3	=	weapon_ar2
				4	=	weapon_shotgun
		KeyValues:
				citizentype	=	3
]]
local weaponsets = {
	weapon_rebel	= {"weapon_pistol", "weapon_smg1", "weapon_ar2", "weapon_shotgun"},
	weapon_combine	= {"weapon_smg1", "weapon_ar2", "weapon_shotgun"},
	weapon_citizen	= {"weapon_citizenpackage", "weapon_citizensuitcase", "weapon_none"}
};

ENT.NPCs         = {};
ENT.Spawned      = 0;
ENT.LastSpawn    = 0;
ENT.LastChange   = 0;
ENT.TotalSpawned = 0;

function ENT:SpawnFunction(ply, tr)
	if (not tr.Hit) then return end
	local ent = ents.Create ("sent_spawnplatform");
	ent:SetPos (tr.HitPos + tr.HitNormal * 16);
	ent:SetPlayer(ply);
	ent:Spawn();
	ent:Activate();
	return ent;
end

numpad.Register ("NPCSpawnerOn", function(ply, ent)
	npcspawner.debug("Numpad on called for", ent, "by", ply);
	if (IsValid(ent)) then
		ent:TurnOn();
	else
		npcspawner.debug("Invalid entity provided?!");
	end
end);

numpad.Register ("NPCSpawnerOff", function(ply, ent)
	npcspawner.debug("Numpad off called for", ent, "by", ply);
	if (IsValid(ent)) then
		ent:TurnOff();
	else
		npcspawner.debug("Invalid entity provided?!");
	end
end);

function ENT:Initialize ()
	npcspawner.debug2(self, "now exists!");
	-- Ensure the right model etc is set
	self:OnActiveChange(nil, nil, self:IsActive());
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid   (SOLID_VPHYSICS);
	local phys = self:GetPhysicsObject();
	if (not IsValid(phys)) then
		ErrorNoHalt("No physics object for ", tostring(self), " using model ", self:GetModel(), "?\n");
	elseif (self:GetFrozen()) then
		phys:EnableMotion(false);
	else
		phys:Wake();
	end

	self:ResetLastSpawn();
	self.Spawned = 0;
	self.NPCs    = {};
	self:UpdateLabel();

	self:CreateWireInputs({
		{
			Name = "SetActive";
			Desc = "Set the active state of the platform";
		};
		{
			Name = "SpawnOne";
			Desc = "Force the spawning of a NPC";
		};
		{
			Name = "NPCClass";
			Desc = "Set the class of NPC to spawn";
			Type = "STRING";
		};
		{
			Name = "MaxActiveNPCs";
			Desc = "Set the max number of active NPCs";
		};
		{
			Name = "SpawnDelay";
			Desc = "Set the spawn delay";
		};
		{
			Name = "Weapon";
			Desc = "Set what weapon to give the NPCs";
			Type = "STRING";
		};
		{
			Name = "HealthMultiplier";
			Desc = "Set the health multiplier for the NPCs";
		};
		{
			Name = "MaxSpawnedNPCs";
			Desc = "Set the total number of NPCs to spawn before turning off";
		};
		{
			Name = "DelayDecreaseAmount";
			Desc = "Set how much to decrease the delay by every MaxActiveNPCs spawned";
		};
		{
			Name = "RemoveNPCs";
			Desc = "Delete all NPCs currently spawned.";
		};
	});
	self:CreateWireOutputs({
		{
			Name = "IsOn";
			Desc = "Is the platform on?";
		};
		{
			Name = "ActiveNPCs";
			Desc = "The number of currently active NPCs";
		};
		{
			Name = "TotalNPCsSpawned";
			Desc = "The total number of NPCs spawned this active session";
		};
		{
			Name = "LastNPCSpawned";
			Desc = "The last NPC the platform spawned";
			Type = "ENTITY";
		};
		{
			Name = "OnNPCSpawned";
			Desc = "Triggered every time a NPC is spawned.";
		};
	});
end

function ENT:RegisterListeners()
	self:NetworkVarNotify("Active", self.OnActiveChange);
	self:NetworkVarNotify("StartDelay", self.OnStartDelayChange);
	self:NetworkVarNotify("PlayerID", self.OnPlayerIDChange);
	self:NetworkVarNotify("Player", self.OnPlayerChange);
	self:NetworkVarNotify("Frozen", self.OnFrozenStateChange);
	self:NetworkVarNotify("OnKey", function(self, _, _, onKey)
		self:RebindNumpads(self:GetPlayer(), onKey, self:GetOffKey());
	end)
	self:NetworkVarNotify("OffKey", function(self, _, _, offKey)
		self:RebindNumpads(self:GetPlayer(), self:GetOnKey(), offKey);
	end)

	local function labelr(self)
		timer.Simple(0, function() self:UpdateLabel() end);
	end
	self:NetworkVarNotify("NPC", labelr);
	self:NetworkVarNotify("NPCWeapon", labelr);
	self:NetworkVarNotify("SpawnDelay", labelr);
	self:NetworkVarNotify("MaxNPCs", labelr);
end

function ENT:OnStartDelayChange(_, _, delay)
	self:SetSpawnDelay(delay);
	self:ResetLastSpawn();
end

-- Recursive functions are fun
local _isInPlayerSet = false;

function ENT:OnPlayerIDChange(_, _, plyID)
	local ply = player.GetByID(plyID);
	_isInPlayerSet = true;
	self:SetPlayer(ply);
	_isInPlayerSet = false;
end

function ENT:OnPlayerChange(_, oldPly, ply)
	if (not _isInPlayerSet) then
		-- Keep this dumb shit synchronised
		local plyIndex = 0;
		if (IsValid(ply)) then
			plyIndex = ply:EntIndex();
		end
		self:SetPlayerID(plyIndex);
	end
	if (ply ~= oldPly) then
		self:RebindNumpads(ply, self:GetOnKey(), self:GetOffKey());
	end
end

function ENT:OnFrozenStateChange(_, _, freeze)
	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:EnableMotion(not freeze);
		if (not freeze) then
			phys:Wake();
		end
	end
end

ENT._prevOnKeypad = false;
ENT._prevOffKeypad = false;
function ENT:RebindNumpads(ply, keyOn, keyOff)
	numpad.Remove(self._prevOffKeypad);
	numpad.Remove(self._prevOnKeypad);
	self._prevOnKeypad = false;
	self._prevOffKeypad = false;

	if (not IsValid(ply)) then
		return;
	end

	if (keyOn) then
		self._prevOnKeypad = numpad.OnDown(ply, keyOn, "NPCSpawnerOn", self);
	end
	if (keyOff) then
		self._prevOffKeypad = numpad.OnDown(ply, keyOff, "NPCSpawnerOff", self);
	end
end

function ENT:Think()
	if (BaseClass.Think) then BaseClass.Think(self); end
	if (self.Spawned < 0) then self.Spawned = 0 end

	if ((not self:IsActive()) or
		self.Spawned >= self:GetMaxNPCs() or
		self.LastSpawn + self:GetSpawnDelay() > CurTime()
	) then
		return;
	end
	self:SpawnOne();
end

--
-- gmod v14.04.19
-- garrysmod\gamemodes\sandbox\gamemode\commands.lua:288
--
local function InternalSpawnNPC( Player, Position, Normal, Class, Equipment, Angles, Offset )

	local NPCList = list.Get( "NPC" )
	local NPCData = NPCList[ Class ]

	-- Don't let them spawn this entity if it isn't in our NPC Spawn list.
	-- We don't want them spawning any entity they like!
	if ( not NPCData ) then
		if ( IsValid( Player ) ) then
			Player:SendLua( "Derma_Message( \"Sorry! You can't spawn that NPC!\" )" )
		end
	return end

	if ( NPCData.AdminOnly and not Player:IsAdmin() ) then return end

	local bDropToFloor = false

	--
	-- This NPC has to be spawned on a ceiling ( Barnacle )
	--
	if ( NPCData.OnCeiling and Vector( 0, 0, -1 ):Dot( Normal ) < 0.95 ) then
		return nil
	end

	--
	-- This NPC has to be spawned on a floor ( Turrets )
	--
	if ( NPCData.OnFloor and Vector( 0, 0, 1 ):Dot( Normal ) < 0.95 ) then
		return nil
	else
		bDropToFloor = true
	end

	if ( NPCData.NoDrop ) then bDropToFloor = false end

	--
	-- Offset the position
	--
	Offset = NPCData.Offset or Offset or 32
	Position = Position + Normal * Offset


	-- Create NPC
	local NPC = ents.Create( NPCData.Class )
	if ( not IsValid( NPC ) ) then return end

	NPC:SetPos( Position )

	-- Rotate to face player (expected behaviour)
	if (not Angles) then
		Angles = Angle( 0, 0, 0 )

		if ( IsValid( Player ) ) then
			Angles = Player:GetAngles()
		end

		Angles.pitch = 0
		Angles.roll = 0
		Angles.yaw = Angles.yaw + 180
	end

	if ( NPCData.Rotate ) then Angles = Angles + NPCData.Rotate end

	NPC:SetAngles( Angles )

	--
	-- This NPC has a special model we want to define
	--
	if ( NPCData.Model ) then
		NPC:SetModel( NPCData.Model )
	end

	--
	-- This NPC has a special texture we want to define
	--
	if ( NPCData.Material ) then
		NPC:SetMaterial( NPCData.Material )
	end

	--
	-- Spawn Flags
	--
	local SpawnFlags = bit.bor( SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK )
	if ( NPCData.SpawnFlags ) then SpawnFlags = bit.bor( SpawnFlags, NPCData.SpawnFlags ) end
	if ( NPCData.TotalSpawnFlags ) then SpawnFlags = NPCData.TotalSpawnFlags end
	NPC:SetKeyValue( "spawnflags", SpawnFlags )

	--
	-- Optional Key Values
	--
	if ( NPCData.KeyValues ) then
		for k, v in pairs( NPCData.KeyValues ) do
			NPC:SetKeyValue( k, v )
		end
	end

	--
	-- This NPC has a special skin we want to define
	--
	if ( NPCData.Skin ) then
		NPC:SetSkin( NPCData.Skin )
	end

	--
	-- What weapon should this mother be carrying
	--

	-- Check if this is a valid entity from the list, or the user is trying to fool us.
	local valid = false
	for _, v in pairs( list.Get( "NPCUsableWeapons" ) ) do
		if v.class == Equipment then valid = true break end
	end

	if ( Equipment and Equipment ~= "none" and valid ) then
		NPC:SetKeyValue( "additionalequipment", Equipment )
		NPC.Equipment = Equipment
	end

	DoPropSpawnedEffect( NPC )

	NPC:Spawn()
	NPC:Activate()

	if ( bDropToFloor and not NPCData.OnCeiling ) then
		NPC:DropToFloor()
	end

	return NPC

end

local function legacySpawn(player, position, normal, class, weapon, angles, offset)
	local npc = ents.Create(class);
	if (not IsValid(npc)) then
		return npc, true;
	end
	npc:SetPos(positionb + normal * offset);
	npc:SetAngles(angles);
	if (weapon ~= "none") then
		npc:SetKeyValue("additionalequipment", weapon);
	end
	return npc;
end

local function rand()
	return math.random() * 2 - 1;
end

local function onremove(npc, platform)
	npcspawner.debug2("onremove", npc, platform);
	if (IsValid(platform)) then
		platform:NPCKilled(npc);
	end
end
local angles = Angle(0, 0, 0);
function ENT:SpawnOne()
	local class = self:GetNPC();

	if (npcspawner.legacy[class]) then
		class = npcspawner.legacy[class];
	end

	local npcdata = list.Get('NPC')[class];
	if (not npcdata and not npcspawner.config.allowdodgy) then
		-- TODO: Error? Message?
		npcspawner.debug(self, "tried to spawn an invalid NPC", class);
		self:TurnOff();
		return false;
	end

	local weapon = self:GetNPCWeapon();
	npcspawner.debug(self, "is spawning a", class, "with a", weapon);
	if (weapon == 'weapon_none' or weapon == 'none') then
		weapon = nil;
	elseif (weaponsets[weapon]) then
		weapon = table.Random(weaponsets[weapon]);
	elseif (npcdata and npcdata.Weapons and (not weapon or weapon == '' or weapon == 'weapon_default')) then
		weapon = table.Random(npcdata.Weapons);
	end

	local ply = self:GetPlayer();
	if (npcspawner.config.callhooks == 1 and IsValid(ply)) then
		if (not gamemode.Call("PlayerSpawnNPC", ply, class, weapon)) then
			self.LastSpawn = CurTime() + 5; -- Disable spawning for 5 seconds so the user isn't spammed
			npcspawner.debug(ply, "has failed the PlayerSpawnNPC hook.");
			return false;
		end
	end

	local position = (self:GetUp() * rand() + self:GetForward() * rand()) * self:GetSpawnRadius();
	local offset = self:GetSpawnHeight();
	npcspawner.debug2("Offset:", position);
	debugoverlay.Line(self:GetPos(), self:GetPos() + position, 10, color_white, true);

	angles.y = position:Angle().y
	debugoverlay.Axis(self:GetPos() + position, angles, 10, 10, true);
	npcspawner.debug2("Angles:", angles);

	position = self:GetPos() + position;
	local normal = self:GetRight() * -1;
	debugoverlay.Line(position, position + normal * offset, 10, Color(255, 255, 0), true);

	local npc, isError;
	if (npcdata) then
		npc = InternalSpawnNPC(ply, position, normal, class, weapon, angles, offset);
	else
		npc, isError = legacySpawn(ply, position, normal, class, weapon, angles, offset);
	end

	if (not IsValid(npc)) then
		self.LastSpawn = CurTime() + 1; -- Disable spawning for a second
		npcspawner.debug(self, "failed to create npc of type", class);
		if (isError) then
			self:TurnOff();
			error("Failed to create a NPC of type '"..class.."'!");
		end
		return false;
	end

	debugoverlay.Line(self:GetPos(), npc:GetPos(), 10, Color(255,0,0), true);
	timer.Simple(0.1, function() if (IsValid(npc)) then
		debugoverlay.Line(self:GetPos(), npc:GetPos(), 10, Color(0,255,0), true);
	end end)

	--
	local squad = self:GetCustomSquad() and "squad" .. self:GetSquadOverride() or tostring(self);
	npcspawner.debug2("Squad:", squad);
	npc:SetKeyValue("squadname", squad);

	local hp = npc:GetMaxHealth();
	local chp = npc:Health();
	-- Bug with nextbots
	if (chp > hp) then
		hp = chp;
	end
	hp = hp * self:GetNPCHealthMultiplier();
	npcspawner.debug2("Health:", hp);
	npc:SetMaxHealth(hp);
	npc:SetHealth(hp);

	if (npc.SetCurrentWeaponProficiency) then
		npc:SetCurrentWeaponProficiency(self:GetNPCSkillLevel());
	end

	if (self:GetNoCollideNPCs()) then
		npcspawner.debug2("Nocollided.");
		npc:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS); -- Collides with everything except interactive debris or debris
	end

	npc:CallOnRemove("NPCSpawnPlatform", onremove, self);
	npcspawner.debug2("NPC Entity:", npc);

	if (npcspawner.config.callhooks == 1)then
		if (IsValid(ply)) then
			gamemode.Call("PlayerSpawnedNPC", ply, npc);
			debugoverlay.Cross(npc:GetPos(), 10, 10, color_white, true);
			if (CPPI) then
				npc:CPPISetOwner(ply);
			end
		end
	end

	self.NPCs[npc] = npc;
	self.Spawned = self.Spawned + 1;
	self.TotalSpawned = self.TotalSpawned + 1;
	self.LastSpawn = CurTime();

	if (self.TotalSpawned % self:GetMaxNPCs() == 0) then
		npcspawner.debug(self.TotalSpawned.." NPCs spawned, decreasing delay ("..self:GetSpawnDelay()..") by "..self:GetDelayDecrease());
		self:SetSpawnDelay(math.max(self:GetSpawnDelay() - self:GetDelayDecrease(), npcspawner.config.mindelay));
	end

	self:TriggerOutput("OnNPCSpawned", self);
	self:TriggerWireOutput("ActiveNPCs", self.Spawned);
	self:TriggerWireOutput("TotalNPCsSpawned", self.TotalSpawned);
	self:TriggerWireOutput("LastNPCSpawned", npc);
	self:TriggerWireOutput("OnNPCSpawned", 1);
	self:TriggerWireOutput("OnNPCSpawned", 0);

	if (self.TotalSpawned == self:GetMaxNPCsTotal()) then -- Since totallimit is 0 for off and totalspawned will always be > 0 at this point, shit works.
		npcspawner.debug("totallimit ("..self:GetMaxNPCsTotal()..") hit. Turning off.");
		self:TriggerOutput("OnLimitReached", self);
		self:TurnOff();
	end
end

function ENT:NPCKilled(npc)
	npcspawner.debug2("NPC Killed:", npc);
	self.NPCs[npc] = nil;
	-- Make the delay apply after the nth NPC dies.
	if (not self:GetLegacySpawnMode() and self.Spawned >= self:GetMaxNPCs()) then
		self.LastSpawn = CurTime();
	end
	self.Spawned = self.Spawned - 1;
	self:TriggerOutput("OnNPCKilled", self);
	self:TriggerWireOutput("ActiveNPCs", self.Spawned);
end

function ENT:Use (activator, caller)
	if (not self:GetCanToggle() or self.LastChange + 1 > CurTime()) then
		return;
	end
	npcspawner.debug(self, "has been used by", activator, caller)
	self:Toggle();
end

function ENT:Toggle()
	if (self:IsActive()) then
		npcspawner.debug(self, "has toggled from on to off.");
		self:TurnOff();
	else
		npcspawner.debug(self, "has toggled from off to on.");
		self:TurnOn();
	end
end

function ENT:TurnOn()
	self:SetActive(true);
	self.TotalSpawned = 0;
	self:SetSpawnDelay(self:GetStartDelay());
	self:TriggerWireOutput("TotalNPCsSpawned", self.TotalSpawned);
end
function ENT:TurnOff()
	self:SetActive(false);
end

function ENT:OnActiveChange(_, _, active)
	npcspawner.debug2(self, "is set to active state:", active);
	local c = self:GetColor();
	local a = c.a;
	if (active) then
		self:SetModel(model_active);
		self.LastSpawn = CurTime();
		self:SetColor(Color(0, 255, 0, a));
	else
		self:SetModel(model_inactive);
		self:SetColor(Color(255, 0, 0, a));
	end
	self:TriggerWireOutput("IsOn", active and 1 or 0);
	self.LastChange = CurTime();
end


function ENT:OnEntityCopyTableFinish(tab)
	if (BaseClass.OnEntityCopyTableFinish) then BaseClass.OnEntityCopyTableFinish(self, tab) end;
	-- Purge all legacy cruft from the dupe
	for key in pairs(tab) do
		if (key:sub(1, 2) == "k_") then
			tab[key] = nil;
		end
	end
end

function ENT:ResetLastSpawn()
	self.LastSpawn = CurTime();
end

function ENT:RemoveNPCs()
	npcspawner.debug(self, "is deleting its NPCs.");
	for ent in pairs(self.NPCs) do
		if IsValid(ent) then
			ent:Remove();
		end
	end
	self.Spawned = 0;
	self:TriggerWireOutput("ActiveNPCs", self.Spawned);
end

function ENT:OnRemove()
	if (BaseClass.OnRemove) then BaseClass.OnRemove(self); end
	npcspawner.debug(self, "has been removed.");
	if (self:GetAutoRemove()) then
		self:RemoveNPCs();
	end
	self:RebindNumpads(NULL, false, false);
end

--[[ Wire based shit ]]--
function ENT:TriggerInput(name, val)
	if (BaseClass.TriggerInput) then BaseClass.TriggerInput(self, name, val); end

	npcspawner.debug2(self, "has recieved wire input with name", name, "and value", val);
	if (name == "SetActive") then
		if (val == 0) then
			self:TurnOff();
		else
			self:TurnOn();
		end
	elseif (name == "RemoveNPCs") then
		if (val ~= 0) then
			self:RemoveNPCs();
		end
	elseif (name == "SpawnOne") then
		if (val ~= 0) then
			self:SpawnOne();
		end
	elseif (name == "NPCClass") then
		self:KeyValue("npc", val);
	elseif (name == "MaxActiveNPCs") then
		self:KeyValue("maximum", val);
	elseif (name == "SpawnDelay") then
		self:KeyValue("delay", val);
	elseif (name == "Weapon") then
		self:KeyValue("weapon", val);
	elseif (name == "HealthMultiplier") then
		self:KeyValue("healthmul", val);
	elseif (name == "MaxSpawnedNPCs") then
		self:KeyValue("totallimit", val);
	elseif (name == "DelayDecreaseAmount") then
		self:KeyValue("decrease", val);
	end
end


--[[ Hammer I/O ]]--
function ENT:AcceptInput(name, activator, called, value)
	if (BaseClass.AcceptInput) then BaseClass.AcceptInput(self, name, activator, called, value); end

	npcspawner.debug2(self, "has just had their", name, "triggered by", tostring(called), "which was caused by", tostring(activator), "and was passed", value);

	if (name == "TurnOn") then
		self:TurnOn();
	elseif (name == "TurnOff") then
		self:TurnOff();
	elseif (name == "RemoveNPCs") then
		self:RemoveNPCs();
	elseif (name == "SpawnOne") then
		self:SpawnOne();
	end

    return true;
end
