--[[
	Lexical Tools - lua\weapons\gmod_tool\stools\moneypot.lua
	Copyright 2010-2012 Lex Robinson

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

TOOL.Category    = "Lexical Tools"
TOOL.Name        = "#tool.moneypot.name"
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
	language.Add("tool.moneypot.desc", "Create a DarkRP Money Pot")
	language.Add("tool.moneypot.0", "Left click to spawn a Money Pot")
	language.Add("tool.moneypot.header", "Allows you to store vast amounts of money in a small box.")
	language.Add("tool.moneypot.weld", "Weld to target")

	-- Other

	language.Add("Undone_moneypot", "Undone Money Pot")
	language.Add("SBoxLimit_moneypots", "You've hit the Money Pots limit!")
	language.Add("Cleanup_moneypots", "Money Pots")
	language.Add("Cleaned_moneypots", "Cleaned up all Money Pots")
	function TOOL:LeftClick(tr)
		return canTool(tr);
	end
	function TOOL.BuildCPanel(cp)
		cp:AddControl("Label", {
			Text = "#tool.moneypot.header",
		});

		cp:AddControl( "Checkbox", {
			Label = "#tool.moneypot.weld",
			Command = "moneypot_weld",
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
