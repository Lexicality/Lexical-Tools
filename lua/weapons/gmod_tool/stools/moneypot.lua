--[[
    Moneypot STool
    Copyright (c) 2010-2014 Lex Robinson
    This code is freely available under the MIT License
--]]

TOOL.Category    = "Lexical Tools"
TOOL.Name        = "#Money Pot"
TOOL.ClientConVar["weld"] = 1

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
	if (SERVER and not game.SinglePlayer()) then return end
	if (CLIENT and game.SinglePlayer()) then return end
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
	
	language.Add("tool.moneypot.name", "Money Pot")
	language.Add("tool.moneypot.desc", "Allows you to store vast amounts of money in a small box.")
	language.Add("tool.moneypot.0", "Left click to spawn a Money Pot")
	
	// Other
	
	language.Add("Undone_moneypot", "Undone Money Pot")
	language.Add("SBoxLimit_moneypots", "You've hit the Money Pots limit!")
	language.Add("Cleanup_moneypots", "Money Pots")
	language.Add("Cleaned_moneypots", "Cleaned up all Money Pots")
	function TOOL:LeftClick(tr)
        return canTool(tr);
    end
	function TOOL.BuildCPanel(cp)
		cp:AddControl("Header", {Text = "#Tool_moneypot_name", Description = "#Tool_moneypot_desc"})
		
		cp:AddControl( "Checkbox", {
			Label = "Weld:";
			Command = "moneypot_weld";
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
	
	local box = MakeMoneyPot(ply, tr.HitPos, angles, "models/props_lab/powerbox02b.mdl");
	if (not box) then return false; end
	box:SetPos(tr.HitPos - tr.HitNormal * box:OBBMins().z);
	
	
	local weld;
	local ent = tr.Entity
	if (IsValid(ent) and not ent:IsWorld() and self:GetClientNumber("weld") ~= 0) then
		weld = constraint.Weld(box, ent, 0, tr.PhysicsBone, 0);
		ent:DeleteOnRemove(box);
	else
	    box:GetPhysicsObject():EnableMotion(false);
	end
    DoPropSpawnedEffect(box);
	
	undo.Create("moneypot");
	undo.AddEntity(box);
	undo.AddEntity(weld);
	undo.SetPlayer(ply);
	undo.Finish();
	
	ply:AddCleanup("moneypots", box);
	ply:AddCleanup("moneypots", weld);

	return true;
end
