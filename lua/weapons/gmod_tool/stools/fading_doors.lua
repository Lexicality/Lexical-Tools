--[[
	Fading Doors - lua\weapons\gmod_tool\stools\fading_doors.lua
	Copyright 2010-2020 Lex Robinson

	Licensed under the Apache License, Version 2.0 (the "License")
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]] --
--[[ Tool Related Settings ]] --
TOOL.Category = "Lexical Tools"
TOOL.Name = "#Fading Doors"

TOOL.ClientConVar["key"] = "5"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["reversed"] = "0"

local function checkTrace(tr)
	return IsValid(tr.Entity) and
		       not (tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsVehicle())
end

if (CLIENT) then
	usermessage.Hook("FadingDoorHurrah!", function()
		GAMEMODE:AddNotify("Fading door has been created!", NOTIFY_GENERIC, 10)
		surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
	end)
	language.Add("tool.fading_doors.name", "Fading Doors")
	language.Add("tool.fading_doors.desc", "Makes anything into a fadable door")
	language.Add("tool.fading_doors.0",
		"Click on something to make it a fading door. Reload to set it back to normal")
	language.Add("Undone_fading_door", "Undone Fading Door")

	function TOOL.BuildCPanel(panel)
		panel:CheckBox("Reversed (Starts invisible, becomes solid)",
			"fading_doors_reversed")
		panel:CheckBox("Toggle Active", "fading_doors_toggle")
		panel:AddControl("Numpad", {Label = "Button", Command = "fading_doors_key"})
	end

	TOOL.LeftClick = checkTrace

	return
end

local function doUndo(undoData, ent)
	fading_doors.RemoveDoor(ent)
end

function TOOL:LeftClick(tr)
	if (not checkTrace(tr)) then
		return false
	end
	local ent = tr.Entity
	local ply = self:GetOwner()
	fading_doors.SetupDoor(ply, ent, {
		key = self:GetClientNumber("key"),
		toggle = self:GetClientNumber("toggle") == 1,
		reversed = self:GetClientNumber("reversed") == 1,
	})
	undo.Create("fading_door")
	undo.AddFunction(doUndo, ent)
	undo.SetPlayer(ply)
	undo.Finish()

	SendUserMessage("FadingDoorHurrah!", ply)
	return true
end

function TOOL:Reload(tr)
	return checkTrace(tr) and fading_doors.RemoveDoor(tr.Entity)
end
