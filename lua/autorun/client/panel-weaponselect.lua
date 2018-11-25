--[[
	NPC Spawn Platforms V2 - lua/autorun/client/panel-weaponselect_.lua
    Copyright 2009-2018 Lex Robinson

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



local PANEL = {}

DEFINE_BASECLASS "DComboBox"

function PANEL:Init()
    self:AddChoice("  Default Weapon",       "weapon_default")
    self:AddChoice("  None",                 "weapon_none"   )
    self:AddChoice(" Random Rebel Weapon",   "weapon_rebel"  )
    self:AddChoice(" Random Combine Weapon", "weapon_combine")
    self:AddChoice(" Random Citizen Weapon", "weapon_citizen")

    for _, tab in pairs(list.Get("NPCUsableWeapons")) do
        self:AddChoice(tab.title, tab.class)
    end
end

function PANEL:ControlValues(data)
    self:SetConVar(data.command)
    self:CheckConVarChanges()
end

function PANEL:OnSelect(i, label, value)
    RunConsoleCommand(self.m_strConVar, value)
end

derma.DefineControl("NPCWeaponSelecter", "Selects a NPC weapon", PANEL, "DComboBox")
