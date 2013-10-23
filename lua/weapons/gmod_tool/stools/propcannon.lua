--[[
	~ Prop Cannons v2 ~
	~ lexi ~
--]]

TOOL.Category		= "Lexical Tools"
TOOL.Name			= "#Prop Cannon v2"

TOOL.ClientConVar["key"]				= 1
TOOL.ClientConVar["force"]				= 20000
TOOL.ClientConVar["delay"]				= 5
TOOL.ClientConVar["recoil"]				= 1
TOOL.ClientConVar["explosive"]			= 1
TOOL.ClientConVar["kill_delay"]			= 5
TOOL.ClientConVar["ammo_model"]			= "models/props_junk/cinderblock01a.mdl"
TOOL.ClientConVar["fire_effect"]		= "Explosion"
TOOL.ClientConVar["cannon_model"]		= "models/props_trainstation/trashcan_indoor001b.mdl"
TOOL.ClientConVar["explosive_power"]	= 10
TOOL.ClientConVar["explosive_radius"]	= 200

cleanup.Register( "propcannons" )

if (SERVER) then
	CreateConVar("sbox_maxpropcannons", 10, "The maximum number of prop cannons you can have out at one time.");
	local function onRemove(self, down, up)
		numpad.Remove(down);
		numpad.Remove(up);
	end
	function MakeCannon(ply, pos, angles, key, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive)
		if (not ply:CheckLimit("propcannons")) then
			return false;
		end
		local cannon = ents.Create( "gmod_propcannon" )
		cannon:SetPos(pos)	
		cannon:SetAngles(angles)
		cannon:Setup(force, model, ammo, recoil, delay, kill, power, radius, effect, explosive);
		cannon:Spawn()
		cannon:SetPlayer(ply)
		-- Make it shiny and black
		cannon:SetMaterial("models/shiny")
		cannon:SetColor(0, 0, 0, 255)
		cannon.numpadKey = key;
		cannon:CallOnRemove("NumpadCleanup", onRemove,
			numpad.OnDown(ply, key, "propcannon_On", cannon),
			numpad.OnUp  (ply, key, "propcannon_Off",cannon)
		);
		cannon:SetCollisionGroup(COLLISION_GROUP_WORLD);
		
		ply:AddCount("propcannons", cannon)
		return cannon;
	end	
	duplicator.RegisterEntityClass( "gmod_propcannon", MakeCannon, "Pos", "Ang", "numpadKey", "fireForce", "Model", "fireModel", "recoilAmount", "fireDelay", "killDelay", "explosivePower", "explosiveRadius", "fireEffect", "fireExplosives");
else
	language.Add("Tool_propcannon_name",	"Prop Cannons v2");
	language.Add("Tool_propcannon_desc",	"A movable cannon that can fire props");
	language.Add("Tool_propcannon_0",		"Click to spawn a cannon. Click on an existing cannon to change it. Right click on a prop to use the model as ammo.");

	language.Add("SBoxLimit_propcannons", "You've hit the Prop Cannonslimit!")
	language.Add("Undone_propcannon",		"Undone Prop Cannon");
	language.Add("Cleanup_propcannons",		"Prop Cannons");
	language.Add("Cleaned_propcannons",		"Cleaned up all Prop Cannons");
end



function TOOL:LeftClick(tr)
	if (not tr.Hit or tr.Entity:IsPlayer()) then
		return false;
	elseif (CLIENT) then
		return true;
	elseif (not util.IsValidPhysicsObject(tr.Entity, tr.PhysicsBone)) then
		return false;
	end
	
	local ply = self:GetOwner();
	local key, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive;
	key 			= self:GetClientNumber("key");
	force			= self:GetClientNumber("force");
	delay			= self:GetClientNumber("delay");
	recoil  		= self:GetClientNumber("recoil");
	explosive		= self:GetClientNumber("explosive");
	kill			= self:GetClientNumber("kill_delay");
	ammo			= self:GetClientInfo  ("ammo_model");
	effect			= self:GetClientInfo  ("fire_effect");
	model			= self:GetClientInfo  ("cannon_model");
	power			= self:GetClientNumber("explosive_power");
	radius			= self:GetClientNumber("explosive_radius");
	explosive 		= tobool(explosive);
	
	if (not (util.IsValidModel(model) and util.IsValidProp(model) and util.IsValidModel(ammo) and util.IsValidProp(ammo))) then
		return false;
	end 
	local ent = tr.Entity;
	if (IsValid(ent) and ent:GetClass() == "gmod_propcannon" and ent:GetPlayer() == ply) then
		ent:Setup(force, model, ammo, recoil, delay, kill, power, radius, effect, explosive);
		return true;
	end
		
	local angles = tr.HitNormal:Angle();
	angles.pitch = angles.pitch + 90;
	
	local cannon = MakeCannon(ply, tr.HitPos, angles, key, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive);
	if (not cannon) then return false; end
	cannon:SetPos(tr.HitPos - tr.HitNormal * cannon:OBBMins().z);
	

	local weld;
	if (IsValid(ent)) then
		weld = constraint.Weld(cannon, ent, 0, tr.PhysicsBone, 0);
		ent:DeleteOnRemove(cannon);
	else
		local phys = cannon:GetPhysicsObject();
		if (IsValid(phys)) then
			phys:EnableMotion(false);
		end
	end
	
	undo.Create("propcannon");
	undo.SetPlayer(ply);
	undo.AddEntity(cannon);
	undo.AddEntity(weld);
	undo.Finish();
	ply:AddCleanup("propcannons", cannon);
	ply:AddCleanup("propcannons", weld);	
	return true
	
end

function TOOL:RightClick(tr)
	if (not (tr.Hit and tr.Entity:IsValid() and tr.Entity:GetClass() == "prop_physics")) then
		return false;
	end
	if (CLIENT) then
		return true;
	end
	local model = tr.Entity:Model();
	if (not util.IsValidModel(model)) then -- you never know
		return false;
	end
	local ply = self:GetOwner();
	ply:ConCommand("propcannon_ammo_model " .. model .. "\n");
	ply:PrintMessage(HUD_PRINTCENTER, "New ammo model selected!");
end

function TOOL:UpdateGhost(ent, ply) --( ent, player )
	if (not IsValid(ent)) then
		return;
	end
	local tr = ply:GetEyeTrace();
	if (not tr.Hit or (IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:GetClass() == "gmod_propcannon"))) then
		ent:SetNoDraw(true);
		return;
	end
	local angles = tr.HitNormal:Angle();
	angles.pitch = angles.pitch + 90;
	ent:SetAngles(angles);
	ent:SetPos(tr.HitPos - tr.HitNormal * ent:OBBMins().z);
	ent:SetNoDraw(false);
end

function TOOL:Think()
	if (SERVER and not game.SinglePlayer()) then return end
	if (CLIENT and game.SinglePlayer()) then return end
	local ent = self.GhostEntity;
	local model = string.lower(self:GetClientInfo("cannon_model"));
	if (not (IsValid(ent) and ent:GetModel() == model)) then
		--[[
		Msg("Remaking ghost! Ent: ", ent);
		if (IsValid(ent)) then
			MsgN(" and it's valid! Chosen model: ", model, " ent's model: ", ent:GetModel(), " Do they match?: ", model == ent:GetModel())
		else
			MsgN(" coz it's invalid.");
		end
		--]]
		self:MakeGhostEntity(model, vector_origin, Angle());
	end
	self:UpdateGhost(self.GhostEntity, self:GetOwner());
end

function TOOL.BuildCPanel(cp)

    local Combo = {};
	Combo["Label"] = "#Presets";
	Combo["MenuButton"] = "1";
	Combo["Folder"] = "propcannon";
	Combo["Options"] = {};
	Combo["Options"]["Default"] = {};
	Combo["Options"]["Default"]["propcannon_key"]				= "1";
	Combo["Options"]["Default"]["propcannon_force"]				= "20000";
	Combo["Options"]["Default"]["propcannon_delay"]				= "5";
	Combo["Options"]["Default"]["propcannon_recoil"]			= "1";
	Combo["Options"]["Default"]["propcannon_explosive"]			= "1";
	Combo["Options"]["Default"]["propcannon_kill_delay"]		= "5";
	Combo["Options"]["Default"]["propcannon_ammo_model"]		= "models/props_junk/cinderblock01a.mdl";
	Combo["Options"]["Default"]["propcannon_fire_effect"]		= "Explosion";
	Combo["Options"]["Default"]["propcannon_cannon_model"]		= "models/props_trainstation/trashcan_indoor001b.mdl";
	Combo["Options"]["Default"]["propcannon_explosive_power"]	= "10";
	Combo["Options"]["Default"]["propcannon_explosive_radius"]	= "100";
	Combo["CVars"] = {}
	Combo["CVars"]["0"]  = "propcannon_key";
	Combo["CVars"]["1"]  = "propcannon_force";
	Combo["CVars"]["2"]  = "propcannon_delay";
	Combo["CVars"]["3"]  = "propcannon_recoil";
	Combo["CVars"]["4"]  = "propcannon_explosive";
	Combo["CVars"]["5"]  = "propcannon_kill_delay";
	Combo["CVars"]["6"]  = "propcannon_ammo_model";
	Combo["CVars"]["7"]  = "propcannon_fire_effect";
	Combo["CVars"]["8"]  = "propcannon_cannon_model";
	Combo["CVars"]["9"]  = "propcannon_explosive_power";
	Combo["CVars"]["10"] = "propcannon_explosive_radius";
	cp:AddControl("ComboBox", Combo )
	
	cp:AddControl( "PropSelect", {
		Label = "Cannon Model:";
		ConVar = "propcannon_cannon_model";
		Category = "Cannons";
		Models = list.Get( "CannonModels" );
	});
	
    cp:AddControl( "Numpad", {
		Label = "Keypad button:";
		Command = "propcannon_key";
		Buttonsize = "22";
	});
    cp:AddControl( "Slider", {
		Label = "Force:";
		Type = "float";
		Min = "0";
		Max = "100000";
		Command = "propcannon_force";
	});
    cp:AddControl( "Slider", {
		Label = "Reload Delay:";
		Type = "float";
		Min = "0";
		Max = "50";
		Command = "propcannon_delay";
	});
    cp:AddControl( "Slider", {
		Label = "Recoil:";
		Type = "float";
		Min = "0";
		Max = "10";
		Command = "propcannon_recoil";
	});
    cp:AddControl( "Slider", {
		Label = "Prop Lifetime:";
		Type = "float";
		Min = "0";
		Max = "30";
		Command = "propcannon_kill_delay";
	});
    cp:AddControl( "Slider", {
		Label = "Explosive Power:";
		Type = "float";
		Min = "0";
		Max = "200";
		Command = "propcannon_explosive_power";
	});
    cp:AddControl( "Slider", {
		Label = "Explosive Radius:";
		Type = "float";
		Min = "0";
		Max = "500";
		Command = "propcannon_explosive_radius";
	});
    cp:AddControl( "Checkbox", {
		Label = "Explode on contact:";
		Command = "propcannon_explosive";
	});
	cp:AddControl( "PropSelect", {
		Label = "Cannon Ammo:";
		ConVar = "propcannon_ammo_model";
		Category = "Ammo";
		Models = list.Get( "CannonAmmoModels" );
	});
	cp:AddControl( "ListBox", {
		Label = "Firing Effect:";
		Options = list.Get( "CannonEffects" );
	});
end

list.Set("CannonModels","models/dav0r/thruster.mdl",{})
--list.Set("CannonModels","models/props_junk/wood_crate001a.mdl",{})
list.Set("CannonModels","models/props_junk/metalbucket01a.mdl",{})
list.Set("CannonModels","models/props_trainstation/trashcan_indoor001b.mdl",{})
list.Set("CannonModels","models/props_junk/trafficcone001a.mdl",{})
list.Set("CannonModels","models/props_c17/oildrum001.mdl",{})
list.Set("CannonModels","models/props_c17/canister01a.mdl",{})
list.Set("CannonModels","models/props_c17/lampshade001a.mdl",{});

list.Set("CannonAmmoModels","models/props_junk/propane_tank001a.mdl",{})
list.Set("CannonAmmoModels","models/props_c17/canister_propane01a.mdl",{})
list.Set("CannonAmmoModels","models/props_junk/watermelon01.mdl",{})
list.Set("CannonAmmoModels","models/props_junk/cinderblock01a.mdl",{})
list.Set("CannonAmmoModels","models/props_debris/concrete_cynderblock001.mdl",{})
list.Set("CannonAmmoModels","models/props_junk/popcan01a.mdl",{})

list.Set("CannonEffects", "Explosion",	{propcannon_fire_effect = "Explosion"});
list.Set("CannonEffects", "Sparks",		{propcannon_fire_effect = "cball_explode"});
list.Set("CannonEffects", "Bomb drop",	{propcannon_fire_effect = "RPGShotDown"});
list.Set("CannonEffects", "Flash",		{propcannon_fire_effect = "HelicopterMegaBomb"});
list.Set("CannonEffects", "Machine Gun",{propcannon_fire_effect = "HelicopterImpact"});
list.Set("CannonEffects", "None",		{propcannon_fire_effect = "none"});
