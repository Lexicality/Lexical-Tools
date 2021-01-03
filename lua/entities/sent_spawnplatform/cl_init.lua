--[[
	NPC Spawn Platforms - lua/entities/sent_spawnplatform/cl_init.lua
    Copyright 2020 Lex Robinson

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
include("shared.lua")

DEFINE_BASECLASS(ENT.Base)

if not WireLib then
	-- Slightly improved performance for sandbox tooltips
	function ENT:Think()
		if (self.BeingLookedAtByLocalPlayer and self:BeingLookedAtByLocalPlayer()) then
			local text = self:GetOverlayText()

			AddWorldTip(self:EntIndex(), text, 0.5, self:GetPos(), self)

			halo.Add({self}, color_white, 1, 1, 1, true, true)
		end
	end
end

local reverseLookupCache
local function primeLookupCache()
	reverseLookupCache = {}
	for _, tab in pairs(list.Get("NPCUsableWeapons")) do
		reverseLookupCache[tab.class] = language.GetPhrase(tab.title)
	end
	for className, tab in pairs(list.Get("NPC")) do
		reverseLookupCache[className] = language.GetPhrase(tab.Name)
	end
	reverseLookupCache["weapon_default"] = language.GetPhrase(
                                       		"menubar.npcs.defaultweapon")
	reverseLookupCache["weapon_none"] = language.GetPhrase("menubar.npcs.noweapon")
	reverseLookupCache["weapon_rebel"] = language.GetPhrase(
                                     		"tool.npc_spawnplatform.weapon_rebel")
	reverseLookupCache["weapon_combine"] = language.GetPhrase(
                                       		"tool.npc_spawnplatform.weapon_combine")
	reverseLookupCache["weapon_citizen"] = language.GetPhrase(
                                       		"tool.npc_spawnplatform.weapon_citizen")
end
hook.Add("Initialize", "NPC Spawn Platforms overlay cache", primeLookupCache)

local function langLookup(text)
	if (not reverseLookupCache) then
		primeLookupCache()
	end
	return reverseLookupCache[text] or text
end

_G.flong = reverseLookupCache
_G.flang = langLookup

function ENT:GetActualOverlayText()
	if (self:IsActive() and self:IsFlipped()) then
		local str = language.GetPhrase("tool.npc_spawnplatform.overlay_flipped")
		local npc = langLookup(self:GetNPC())

		return string.format(str, npc)
	end

	local str = language.GetPhrase("tool.npc_spawnplatform.overlay")
	local npc = langLookup(self:GetNPC())
	local weapon = langLookup(self:GetNPCWeapon())
	local spawnDelay = self:GetSpawnDelay()
	local maxnpcs = self:GetMaxNPCs()
	-- RIP translations
	if spawnDelay < 10 then
		spawnDelay = string.format("%.2f seconds", spawnDelay)
	else
		spawnDelay = string.NiceTime(spawnDelay)
	end
	return string.format(str, npc, weapon, spawnDelay, maxnpcs)
end

-- Sandbox
function ENT:GetOverlayText()
	local txt = self:GetActualOverlayText()

	if (game.SinglePlayer()) then
		return txt
	end

	local ownerName = self:GetPlayerName()
	if (ownerName ~= "") then
		txt = txt .. "\n(" .. ownerName .. ")"
	end

	return txt
end

-- Wiremod
function ENT:GetOverlayData()
	return {txt = self:GetActualOverlayText()}
end
