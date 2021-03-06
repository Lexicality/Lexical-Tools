--[[
	Keypads - lua/entities/keypad/cl_init.lua
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
DEFINE_BASECLASS "base_lexentity"

ENT.Type = "anim"
ENT.PrintName = "Keypad"
ENT.Author = "Lexi"
ENT.Contact = "lexi@lexi.org.uk"
ENT.CountKey = "keypads"

ENT.Spawnable = true
ENT.AdminOnly = false

ENT.IsKeypad = true

ENT.STATUSES = {Normal = 0, AccessGranted = 1, AccessDenied = 2}

ENT._NWVars = {
	{Type = "String", Name = "PasswordDisplay"},
	{Type = "Bool", Name = "Secure", KeyName = "secure"},
	{Type = "Int", Name = "Status", Default = ENT.STATUSES.Normal},
	{Type = "Bool", Name = "BeingCracked"},
}

ENT.KeyPositions = {
	{-2.2, 1.25, 4.55, 1.3},
	{-0.6, 1.25, 4.55, 1.3},
	{1.0, 1.25, 4.55, 1.3},

	{-2.2, 1.25, 2.90, 1.3},
	{-0.6, 1.25, 2.90, 1.3},
	{1.0, 1.25, 2.90, 1.3},

	{-2.2, 1.25, 1.30, 1.3},
	{-0.6, 1.25, 1.30, 1.3},
	{1.0, 1.25, 1.30, 1.3},

	{-2.2, 2, -0.30, 1.6},
	{0.3, 2, -0.30, 1.6},
}

-- The spot on the keypad where special effects should hit the keypad
function ENT:GetZapPos()
	-- Work out the centre of the screen
	return self:GetPos() + self:GetUp() * 3.5 + self:GetForward() * 1
end

-- Backwards compat etc etc
-- Who names a var this generically??
function ENT:GetText()
	return self:GetPasswordDisplay()
end

function ENT:SetText(value)
	return self:SetPasswordDisplay(value)
end
