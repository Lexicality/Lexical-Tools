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
]] --
DEFINE_BASECLASS "weapon_keypad_cracker"

AddCSLuaFile()

SWEP.Category = "Roleplay"
SWEP.PrintName = "Über Keypad Cracker"
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.Author = "Lexi"
SWEP.Spawnable = true
SWEP.AdminOnly = true

function SWEP:GetCrackTime(target)
	-- Instantly break open any keypad
	return 0
end
