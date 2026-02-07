--[[
	Keypads - examples/weapon_uber_cracker.lua
	Copyright 2012-2018 Lex Robinson

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]]
DEFINE_BASECLASS("weapon_keypad_cracker")

AddCSLuaFile()

SWEP.Category = "Roleplay"
SWEP.PrintName = "My Server's Keypad Cracker"
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.Author = "Lexi"
SWEP.Spawnable = true
SWEP.AdminOnly = true

function SWEP:GetCrackTime(target)
	local crackTime = cvars.Number("keypad_cracker_time", 15)
	local victim = target:GetPlayer()
	if IsValid(victim) then
		-- The mob boss can break into gun dealers' bases really easily
		if self.Owner:Team() == _G.TEAM_MOB and victim:Team() == _G.TEAM_GUN then
			return crackTime * 0.5
		end
	end
	return crackTime
end
-- Instantly break open any keypad
SWEP.CrackTime = 0
