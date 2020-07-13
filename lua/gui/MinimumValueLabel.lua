--[[
	Keypads - lua/gui/MinimumValueLabel.lua
	Copyright 2018 Lex Robinson

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]] --
local PANEL = {}

AccessorFunc(PANEL, "m_sName", "CtrlName")
AccessorFunc(PANEL, "m_sCVarMin", "MinimumCVar")
AccessorFunc(PANEL, "m_sCVarActual", "ActualCVar")

function PANEL:OnConVarChange(min, val)
	min = tonumber(min) or 0
	val = tonumber(val) or 0
	if (val < min) then
		self:DoText(
			string.format("This server's minimum %s is %d", self:GetCtrlName(), min)
		)
	else
		self:DoText("")
	end
end

function PANEL:ControlValues(data)
	self:SetCtrlName(data.name)
	self:SetConVars({data.minimum, data.cvar})
	self:HandleCVarChange()
end

derma.DefineControl(
	"MinimumValueLabel", "Tell players about defined minima", PANEL, "NagLabel"
)
