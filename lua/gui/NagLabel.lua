--[[
	Keypads - lua/gui/NagLabel.lua
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

Derma_Install_Better_Convar_Functions(PANEL)

function PANEL:Init()
	self:SetHighlight(true)
end

function PANEL:DoText(value)
	if (value ~= "") then
		self:SetHeight(20)
		self:SetText(value)
	else
		self:SetHeight(0)
	end
end

function PANEL:ControlValues(data)
	if (data.cvars) then
		self:SetConVars(data.cvars)
	end
end

function PANEL:OnRemove()
	self:NukeConVars()
end

derma.DefineControl("NagLabel",
                    "A label for displaying dire news on cvar changes", PANEL,
                    "DLabel")
