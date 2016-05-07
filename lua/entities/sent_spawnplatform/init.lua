--[[
	NPC Spawn Platforms V2
    Copyright (c) 2011-2016 Lex Robinson
    This code is freely available under the MIT License
--]]

--[[ Make the platform dupable ]]--
duplicator.RegisterEntityClass("sent_spawnplatform",  function(ply,  pos,  angles,  data)
    local ent = ents.Create("sent_spawnplatform");
    ent:SetAngles(angles);
    ent:SetPos(pos);
    for key, value in pairs(data) do
        if (key:sub(1, 2) == "k_") then
            ent:SetKeyValue(key:sub(3), value);
        end
    end
    ent:Spawn();
    ent:Activate();
    -- If it's being loaded from a savegame ply might be nil
    if (IsValid(ply)) then
        ent:SetKeyValue("ply", ply:EntIndex());
        ply:AddCount("sent_spawnplatform", ent);
    end
    return ent;
end,  "Pos",  "Angle",  "Data");
AddCSLuaFile("shared.lua");
include('shared.lua');
local model1 = Model("models/props_c17/streetsign004e.mdl");
local model2 = Model("models/props_c17/streetsign004f.mdl");
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
	weapon_rebel	= {"weapon_pistol",  "weapon_smg1",  "weapon_ar2",  "weapon_shotgun"},
	weapon_combine	= {"weapon_smg1",  "weapon_ar2",  "weapon_shotgun"},
	weapon_citizen	= {"weapon_citizenpackage",  "weapon_citizensuitcase",  "weapon_none"}
};

-- Default Settings
ENT.k_npc				= "npc_combine_s";
ENT.k_weapon			= "weapon_smg1";
ENT.k_spawnheight		= 16;
ENT.k_spawnradius		= 16;
ENT.k_maximum			= 5;
ENT.k_delay				= 5;
ENT.k_onkey				= 2;
ENT.k_offkey			= 1;
ENT.k_healthmul			= 1;
ENT.k_toggleable		= 1;
ENT.k_autoremove		= 1;
ENT.k_squadoverride		= 1;
ENT.k_customsquads		= 0;
ENT.k_totallimit		= 0;
ENT.k_decrease			= 0;
ENT.k_active			= 0;
ENT.k_ply				= 0;
ENT.k_skill				= WEAPON_PROFICIENCY_AVERAGE;
ENT.NPCs 				= {};
ENT.Spawned             = 0;
ENT.LastSpawn           = 0;
ENT.LastChange          = 0;
ENT.TotalSpawned		= 0;
ENT.Delay               = 5;

function ENT:SpawnFunction(ply,  tr)
	if (not tr.Hit) then return end
	local ent = ents.Create ("sent_spawnplatform");
	ent:SetPos (tr.HitPos + tr.HitNormal * 16);
	ent:Spawn();
	ent:Activate();
	return ent;
end

numpad.Register ("NPCSpawnerOn",  function(ply,  ent)
	npcspawner.debug("Numpad on called for", ent, "by", ply);
	if (IsValid(ent)) then
		ent:TurnOn();
	else
		npcspawner.debug("Invalid entity provided?!");
	end
end);

numpad.Register ("NPCSpawnerOff",  function(ply,  ent)
	npcspawner.debug("Numpad off called for",  ent,  "by",  ply);
	if (IsValid(ent)) then
		ent:TurnOff();
	else
		npcspawner.debug("Invalid entity provided?!");
	end
end);

function ENT:Initialize ()
	self:SetModel(model1);
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid	(SOLID_VPHYSICS);
	local phys = self:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:Wake();
	else
		ErrorNoHalt("No physics object for ", tostring(self), " using model ", model1, "?\n");
	end
	self.LastSpawn  = 0;
	self:CheckActive();
	self.Spawned  = 0;
	self.NPCs   = {};
	if (WireLib) then
	--[[ People wanted wire control,  here is your wire control. ]]--
		WireLib.CreateSpecialInputs (self,  {
			"SetActive", 				-- active
			"SpawnOne",
			"NPCClass", 				-- npc
			"MaxActiveNPCs", 		-- maximum
			"SpawnDelay", 			-- delay
			"Weapon", 				-- weapon
			"HealthMultiplier", 		-- healthmul
			"MaxSpawnedNPCs", 		-- totallimit
			"DelayDecreaseAmount", 	-- decrease
			"RemoveNPCs",
				},  {
			"NORMAL",
			"NORMAL",
			"STRING",
			"NORMAL",
			"NORMAL",
			"STRING",
			"NORMAL",
			"NORMAL",
			"NORMAL",
			"NORMAL"
			--[[
				}, {
			"Set the active state of the platform",
			"Force the spawning of a NPC",
			"Set the class of NPC to spawn",
			"Set the max number of active NPCs",
			"Set the spawn delay",
			"Set what weapon to give the NPCs",
			"Set the health multiplier for the NPCs",
			"Set how much to decrease the delay by every MaxActiveNPCs spawned",
			"Delete all NPCs currently spawned."
			--]]
		});
		WireLib.CreateSpecialOutputs(self,  {
			"IsOn",
			"ActiveNPCs",
			"TotalNPCsSpawned",
			"LastNPCSpawned",
			"OnNPCSpawned"
				},  {
			"NORMAL",  "NORMAL",  "NORMAL",  "ENTITY",  "NORMAL"
			--[[	}, {
			"Is the platform on?",
			"The number of currently active NPCs",
			"The total number of NPCs spawned this active session",
			"The last NPC the platform spawned",
			"Triggered every time a NPC is spawned."--]]
		});
	end
	self.Ply = player.GetByID(tonumber(self.k_ply));
	if (not IsValid(self.Ply)) then return end
	numpad.OnDown (self.Ply,  self.k_onkey,   "NPCSpawnerOn",   self);
	numpad.OnDown (self.Ply,  self.k_offkey,  "NPCSpawnerOff",  self);
end

function ENT:Think()
	if (self.Spawned < 0) then self.Spawned = 0 end
	if (self._WireSpawnedActive) then
		Wire_TriggerOutput(self,  "OnNPCSpawned",  0);
		self._WireSpawnedActive = nil;
	end
	if (self.k_active == 0 or self.Spawned >= self.k_maximum or self.LastSpawn + self.k_delay > CurTime()) then return end
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
	if (IsValid(platform)) then
		platform:NPCKilled(npc);
	end
end
local angles = Angle(0, 0, 0);
function ENT:SpawnOne()
	local class = self.k_npc;
	if ( npcspawner.legacy[ class ] ) then
		class = npcspawner.legacy[ class ];
	end
	local npcdata = list.Get('NPC')[ class ];
	if ( not npcdata and not npcspawner.config.allowdodgy ) then
		-- TODO: Error? Message?
		npcspawner.debug(self, "tried to spawn an invalid NPC", class);
		self:TurnOff();
		return false;
	end
	local weapon = self.k_weapon;
	npcspawner.debug(self, "is spawning a", class, "with a", weapon);
	if (weapon == 'weapon_none' or weapon == 'none') then
		weapon = nil;
	elseif (weaponsets[ weapon ]) then
		weapon = table.Random(weaponsets[ weapon ]);
	elseif (npcdata and npcdata.Weapons and (not weapon or weapon == '' or weapon == 'weapon_default')) then
		weapon = table.Random(npcdata.Weapons);
	end
	if (npcspawner.config.callhooks == 1 and IsValid(self.Ply)) then
		if (not gamemode.Call("PlayerSpawnNPC", self.Ply, class, weapon)) then
			self.LastSpawn = CurTime() + 5; -- Disable spawning for 5 seconds so the user isn't spammed
			npcspawner.debug(self.Ply,  "has failed the PlayerSpawnNPC hook.");
			return false;
		end
	end
	local position = (self:GetUp() * rand() + self:GetForward() * rand() ) * self.k_spawnradius;
	local offset = self.k_spawnheight;
	npcspawner.debug2("Offset:",  position);
	debugoverlay.Line(self:GetPos(), self:GetPos() + position, 10, color_white, true );
	angles.y = position:Angle().y
	debugoverlay.Axis(self:GetPos() + position, angles, 10, 10, true);
	npcspawner.debug2("Angles:",  angles);
	position = self:GetPos() + position;
	local normal = self:GetRight() * -1;
	debugoverlay.Line(position, position + normal * offset, 10, Color(255, 255, 0), true );

	local npc, isError;
	if (npcdata) then
		npc = InternalSpawnNPC(self.Ply, position, normal, class, weapon, angles, offset);
	else
		npc, isError = legacySpawn(self.Ply, position, normal, class, weapon, angles, offset);
	end

	if (not IsValid(npc)) then
		self.LastSpawn = CurTime() + 1; -- Disable spawning for a second
		npcspawner.debug( self, "failed to create npc of type", class );
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
	local squad = (self.k_customsquads == 1) and "squad"..self.k_squadoverride or tostring(self);
	npcspawner.debug2("Squad:", squad);
	npc:SetKeyValue("squadname", squad);
	local hp = npc:GetMaxHealth();
	local chp = npc:Health();
	-- Bug with nextbots
	if (chp > hp) then
		hp = chp;
	end
	hp = hp * self.k_healthmul;
	npcspawner.debug2("Health:", hp);
	npc:SetMaxHealth(hp);
	npc:SetHealth(hp);
	if (npc.SetCurrentWeaponProficiency) then
		npc:SetCurrentWeaponProficiency(self.k_skill);
	end
	if (self.k_nocollide == 1) then
		npcspawner.debug2("Nocollided.");
		npc:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS); -- Collides with everything except interactive debris or debris
	end
	npc:CallOnRemove("NPCSpawnPlatform", onremove, self);
	npcspawner.debug2("NPC Entity:", npc);
	if (npcspawner.config.callhooks == 1)then
		if (IsValid(self.Ply)) then
			gamemode.Call("PlayerSpawnedNPC", self.Ply, npc);
			debugoverlay.Cross(npc:GetPos(), 10, 10, color_white, true);
		end
	end
	self.NPCs[npc] = npc;
	self.Spawned = self.Spawned + 1;
	self.TotalSpawned = self.TotalSpawned + 1;
	self.LastSpawn = CurTime();
	if (self.TotalSpawned % self.k_maximum == 0) then
		npcspawner.debug(self.TotalSpawned.." NPCs spawned,  decreasing delay ("..self.k_delay..") by "..self.k_decrease);
		self.k_delay = math.max(self.k_delay - self.k_decrease, npcspawner.config.mindelay);
	end
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "ActiveNPCs",  self.Spawned);
		Wire_TriggerOutput(self,  "TotalNPCsSpawned",  self.TotalSpawned);
		Wire_TriggerOutput(self,  "LastNPCSpawned",  npc);
		Wire_TriggerOutput(self,  "OnNPCSpawned",  1);
		Wire_TriggerOutput(self,  "OnNPCSpawned",  0);
		--self._WireSpawnedActive = true;
	end
	if (self.TotalSpawned == self.k_totallimit) then -- Since totallimit is 0 for off and totalspawned will always be > 0 at this point,  shit works.
		npcspawner.debug("totallimit ("..self.k_totallimit..") hit. Turning off.");
		self:TurnOff();
	end
end

function ENT:NPCKilled(npc)
	npcspawner.debug2("NPC Killed:", npc);
	self.NPCs[npc] = nil;
	self.Spawned = self.Spawned - 1;
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "ActiveNPCs",  self.Spawned);
	end
end

function ENT:Use (activator,  caller)
	if (self.k_toggleable == 0 or self.LastChange + 1 > CurTime()) then
		return;
	end
	npcspawner.debug(self, "has been used by", activator, caller)
	self:Toggle();
end

function ENT:Toggle()
	if (self.k_active == 0) then
		npcspawner.debug(self, "has toggled from off to on.");
		self:TurnOn();
	else
		npcspawner.debug(self, "has toggled from on to off.");
		self:TurnOff();
	end
end

function ENT:TurnOn()
	self.k_active = 1;
	self.TotalSpawned = 0;
	self.k_delay = self.Delay;
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "TotalNPCsSpawned",  self.TotalSpawned);
	end
	self:CheckActive();
end
function ENT:TurnOff()
	self.k_active = 0;
	self:CheckActive();
end

local color_on  = Color(0, 255, 0);
local color_off = Color(255, 0, 0);
local _, oldStyleGetColor, a, c;
function ENT:CheckActive()
	c, oldStyleGetColor, _, a = self:GetColor();
	if (self.k_active == 1) then
		self:SetModel (model1);
		self.LastSpawn = CurTime();
        if (oldStyleGetColor) then
            self:SetColor (0, 255, 0, a);
        else
            if (self.GetAlpha) then
                local a = self:GetAlpha();
                self:SetColor(color_on);
                self:SetAlpha(a);
            else
                c.r = 0;
                c.g = 255;
                c.b = 0;
                self:SetColor(c);
            end
        end
	else
		self:SetModel (model2);
        if (oldStyleGetColor) then
            self:SetColor (255, 0, 0, a);
        else
            if (self.GetAlpha) then
                local a = self:GetAlpha();
                self:SetColor(color_off);
                self:SetAlpha(a);
            else
                c.r = 255;
                c.g = 0;
                c.b = 0;
                self:SetColor(c);
            end
        end
	end
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "IsOn",  self.k_active);
	end
	self:SetNWString("active",  self.k_active);
	self.LastChange = CurTime();
end

local nwablekeys = {
	npc		= true,
	weapon	= true,
	maximum	= true,
	delay	= true
}
-- Using keyvalues allows us to have a callback for each value,  should it be needed.
function ENT:KeyValue(key,  value)
	npcspawner.debug2("Key:", key, "Value:", value);
    key = string.lower(key);
	if (key == "delay") then
        value = tonumber(value);
        if (not value) then return; end
		self.LastSpawn = CurTime();
		self.Delay = value;
		value = math.max(value,npcspawner.config.mindelay);
	elseif (key == "active") then
		self:CheckActive();
	end
	self["k_"..key] = tonumber(value) or value;
	if (nwablekeys[key]) then -- Only some keys need to be networked,  let's try to keep traffic as low as possible :D
		self:SetNWString(key,  value);
		self:UpdateLabel();
	end
end

function ENT:RemoveNPCs()
	npcspawner.debug(self, "is deleting its NPCs.");
	for ent in pairs(self.NPCs) do
		if IsValid(ent) then
			ent:Remove();
		end
	end
	self.Spawned = 0;
	if (Wire_TriggerOutput) then
		Wire_TriggerOutput(self,  "ActiveNPCs",  self.Spawned);
	end
end

function ENT:OnRemove()
	npcspawner.debug(self, "has been removed.");
	if (self.k_autoremove == 1) then
		self:RemoveNPCs();
	end
end

--[[ Wire based shit ]]--
function ENT:TriggerInput(name,  val)
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
-- function ENT:AcceptInput(name, activator, called, value)
-- 	--npcspawner.debug2(self, "has just had their", name, "triggered by", tostring(called), "which was caused by", tostring(activator), "and was passed", value);
-- 	MsgN(self, " had their '", name, "' input triggered by ", tostring(called), " which was caused by ", tostring(activator), " and was passed '", value, "'");
--     name = string.lower(name);
--     return true;
-- end
