--[[
	~ Money Pot STool ~
	~ Lexi ~
--]]

TOOL.Category    = "Lexical Tools"
TOOL.Name        = "#Money Pot"
TOOL.ClientConVar["weld"] = 1
TOOL.ClientConVar["model"] = "models/props_lab/powerbox02b.mdl";
if (not WireLib) then -- This is useless without Wire, so just disable it.
	TOOL.AddToMenu		= false
	return;
end

list.Set("CommandboxModelOffsets","models/props_lab/powerbox02a.mdl",Vector(0, 0, 17));
list.Set("CommandboxModelOffsets","models/props_lab/powerbox02b.mdl",Vector(0, 0, 17));
list.Set("CommandboxModelOffsets","models/props_lab/powerbox02c.mdl",Vector(0, 0, 10));

local models = list.GetForEdit("CommandboxModels") -- <3 u pass by refernce and how you keep my tables up to date.

cleanup.Register("moneypots")

function TOOL:UpdateGhost(ent, ply)
	if (not IsValid(ent)) then
		return;
	end
	local tr = ply:GetEyeTrace();
	if (not tr.Hit or (IsValid(tr.Entity) and (tr.Entity:IsPlayer()))) then
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
	if (SERVER and not SinglePlayer()) then return end
	if (CLIENT and SinglePlayer()) then return end
	local ent = self.GhostEntity;
	if (not IsValid(ent)) then
		self:MakeGhostEntity("models/props_lab/powerbox02b.mdl", vector_origin, Angle());
	end
	self:UpdateGhost(self.GhostEntity, self:GetOwner());
end

local function canTool(tr)
	return tr.Hit and not tr.Entity:IsPlayer()
end

if (CLIENT) then
	
	language.Add("Tool_moneypot_name", "Money Pot")
	language.Add("Tool_moneypot_desc", "Allows you to store vast amounts of money in a small box.")
	language.Add("Tool_moneypot_0", "Left click to spawn a Money Pot")
	
	// Other
	
	language.Add("Undone_moneypot", "Undone Money Pot")
	language.Add("SBoxLimit_moneypots", "You've hit the Money Pots limit!")
	language.Add("Cleanup_moneypots", "Money Pots")
	language.Add("Cleaned_moneypots", "Cleaned up all Money Pots")
	TOOL.LeftClick = canTool;
	function TOOL.BuildCPanel(cp)
		cp:AddControl("Header", {Text = "#Tool_moneypot_name", Description = "#Tool_moneypot_desc"})
		
		cp:AddControl( "Checkbox", {
			Label = "Weld:";
			Command = "moneypot_weld";
		});
		local tab = {}
		for model in pairs(models) do
			tab[model] = {};
		end
		cp:AddControl("Prop Select", {
			Label = "Model:";
			ConVar = "moneypot_model";
			Models = tab;
		});
			
	end
	return;
end

CreateConVar("sbox_maxmoneypots", 10, FCVAR_NOTIFY)

function TOOL:LeftClick(tr)
	if (not canTool(tr)) then
		return false;
	end

	local ply = self:GetOwner();
		
	local angles = tr.HitNormal:Angle();
	angles.pitch = angles.pitch + 90;
	
	local model = self:GetClientInfo("model");
	
	local box = MakeMoneyPot(ply, tr.HitPos, angles, "models/props_lab/powerbox02b.mdl");
	if (not box) then return false; end
	box:SetPos(tr.HitPos - tr.HitNormal * box:OBBMins().z);
	
	
	local weld;
	local ent = tr.Entity
	if (IsValid(ent) and not ent:IsWorld() and self:GetClientNumber("weld") ~= 0) then
		weld = constraint.Weld(box, ent, 0, tr.PhysicsBone, 0);
		ent:DeleteOnRemove(box);
	else
		local phys = box:GetPhysicsObject();
		if (IsValid(phys)) then
			phys:EnableMotion(false);
		end
	end
	
	undo.Create("moneypot");
	undo.AddEntity(box);
	undo.AddEntity(weld);
	undo.SetPlayer(ply);
	undo.Finish();
	
	ply:AddCleanup("moneypots", box);
	ply:AddCleanup("moneypots", weld);
	
	return true;
end

// Create command box
function MakeMoneyPot(ply, pos, angles, model, data)
	if (not ply:CheckLimit("moneypots")) then
		return false;
	end
	local box;
	if (data) then
		box = duplicator.GenericDuplicatorFunction(ply, data); -- This is actually better than doing it manually
	else
		box = ents.Create("gmod_wire_moneypot");
		box:SetModel(model)
		box:SetPos(pos);
		box:SetAngles(angles);
		box:Spawn();
	end
	box:SetPlayer(ply);
	ply:AddCount("moneypots", box);
	return box;
end

duplicator.RegisterEntityClass("gmod_wire_moneypot", MakeMoneyPot, "Pos", "Ang", "Model", "Data");

