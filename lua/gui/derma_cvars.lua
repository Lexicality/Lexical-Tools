--[[
	Better Derma ConVar Functions - lua/gui/derma_cvars.lua
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
function Derma_Install_Better_Convar_Functions(PANEL)
	AccessorFunc(PANEL, "m_tCvars", "ConVars")
	PANEL.m_tCvars = {}

	function PANEL:OnConVarChange(...)
		error("Abstract Method")
	end

	function PANEL:HandleCVarChange()
		local values = {}
		for _, cvar in pairs(self:GetConVars()) do
			table.insert(values, cvars.String(cvar))
		end
		self:OnConVarChange(unpack(values))
	end

	function PANEL:NukeConVars()
		for _, cvar in pairs(self:GetConVars()) do
			cvars.RemoveChangeCallback(cvar, self._cvarid)
		end
	end

	function PANEL:SetConVars(convars)
		if (not self._cvarid) then
			self._cvarid = tostring(math.random(10000, 99999))
		end

		self:NukeConVars()

		local cb = function()
			self:HandleCVarChange()
		end

		for _, cvar in pairs(convars) do
			cvars.AddChangeCallback(cvar, cb, self._cvarid)
		end

		self.m_tCvars = convars
	end
end
