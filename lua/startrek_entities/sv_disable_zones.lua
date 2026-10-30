StarTrekEntities = StarTrekEntities or {}
StarTrekEntities.DisableZones = StarTrekEntities.DisableZones or {}

local DisableZones = StarTrekEntities.DisableZones

DisableZones.SystemClasses = {
	lifesupport = {
		deck = "disablelifesupport_deck",
		section = "disablelifesupport_section",
	},
	gravity = {
		deck = "disablegravity_deck",
		section = "disablegravity_section",
	},
}

DisableZones.Data = DisableZones.Data or {}
DisableZones.Entities = DisableZones.Entities or {}
DisableZones.PlayerLocations = DisableZones.PlayerLocations or {}
DisableZones.EmptyLocation = DisableZones.EmptyLocation or {}

local function ClearTable(tbl)
	for k in pairs(tbl) do
		tbl[k] = nil
	end
end

local function NotifyAdmins(message)
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsAdmin() then
			ply:ChatPrint(message)
		end
	end
end

function DisableZones:GetSystemData(system)
	local data = self.Data[system]
	if not data then
		data = {
			decks = {},
			sections = {},
		}
		self.Data[system] = data
	end

	return data
end

function DisableZones:SetPlayerLocation(ply, deck, section)
	if not IsValid(ply) then return end

	self.PlayerLocations[ply] = {
		deck,
		section,
		deck = deck,
		section = section,
	}
end

function DisableZones:GetPlayerLocation(ply)
	return self.PlayerLocations[ply] or self.EmptyLocation
end

function DisableZones:PrimePlayers()
	if not Star_Trek or not Star_Trek.Sections then return end

	for _, ply in player.Iterator() do
		local success, deck, section = Star_Trek.Sections:DetermineSection(ply:GetPos())
		if success then
			self:SetPlayerLocation(ply, deck, section)
		else
			self.PlayerLocations[ply] = nil
		end
	end
end

function DisableZones:Add(system, scope, deck, section)
	if deck == nil then return end
	if scope == "section" and section == nil then return end

	local data = self:GetSystemData(system)
	if scope == "deck" then
		data.decks[deck] = (data.decks[deck] or 0) + 1
		return
	end

	local sections = data.sections[deck]
	if not sections then
		sections = {}
		data.sections[deck] = sections
	end
	sections[section] = (sections[section] or 0) + 1
end

function DisableZones:Remove(system, scope, deck, section)
	local data = self.Data[system]
	if not data or deck == nil then return end

	if scope == "deck" then
		local count = data.decks[deck]
		if not count then return end

		if count <= 1 then
			data.decks[deck] = nil
		else
			data.decks[deck] = count - 1
		end
		return
	end

	local sections = data.sections[deck]
	if not sections or section == nil then return end

	local count = sections[section]
	if not count then return end

	if count <= 1 then
		sections[section] = nil
	else
		sections[section] = count - 1
	end

	if next(sections) == nil then
		data.sections[deck] = nil
	end
end

function DisableZones:RegisterEntity(ent, system, scope)
	if not IsValid(ent) then return end

	self:UnregisterEntity(ent)
	self.Entities[ent] = {
		system = system,
		scope = scope,
		deck = ent.Deck,
		section = ent.Section,
	}

	self:Add(system, scope, ent.Deck, ent.Section)
end

function DisableZones:UnregisterEntity(ent)
	local info = self.Entities[ent]
	if not info then return false end

	self:Remove(info.system, info.scope, info.deck, info.section)
	self.Entities[ent] = nil
	return true
end

function DisableZones:Rebuild(system)
	local classes = self.SystemClasses[system]
	if not classes then return end

	local data = self:GetSystemData(system)
	ClearTable(data.decks)
	ClearTable(data.sections)

	for ent, info in pairs(self.Entities) do
		if not IsValid(ent) or info.system == system then
			self.Entities[ent] = nil
		end
	end

	for scope, class in pairs(classes) do
		for _, ent in ipairs(ents.FindByClass(class)) do
			if IsValid(ent) and ent.Deck ~= nil then
				self:RegisterEntity(ent, system, scope)
			end
		end
	end
end

function DisableZones:IsDisabled(system, deck, section)
	local data = self.Data[system]
	if not data or deck == nil then return false end

	if data.decks[deck] then
		return true
	end

	local sections = data.sections[deck]
	return sections and section ~= nil and sections[section] ~= nil or false
end

function DisableZones:IsPlayerDisabled(system, ply)
	local location = self:GetPlayerLocation(ply)
	return self:IsDisabled(system, location.deck, location.section)
end

function DisableZones:InitializeEntity(ent, config)
	if not IsValid(ent) or not config then return false end

	ent:SetModel(config.model)
	ent:PhysicsInit(SOLID_VPHYSICS)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetSolid(SOLID_VPHYSICS)
	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	ent:SetPos(ent:GetPos() + Vector(0, 0, 70))
	ent:DropToFloor()

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end

	if config.color then
		ent:SetColor(config.color)
	end

	local success, deck, section = Star_Trek.Sections:DetermineSection(ent:GetPos())
	if not success then
		NotifyAdmins("You can't place this entity here. It's not a valid location.")
		print("Failed to determine section for " .. tostring(config.name or ent:GetClass()) .. " at position: " .. tostring(ent:GetPos()))
		ent:Remove()
		return false
	end

	ent.Deck = deck
	ent.Section = config.scope == "section" and section or nil

	self:RegisterEntity(ent, config.system, config.scope)
	hook.Run(config.created_hook, ent)

	return true
end

function DisableZones:RemoveEntity(ent, removed_hook)
	if not ent then return end

	local removed = self:UnregisterEntity(ent)
	if removed and removed_hook then
		hook.Run(removed_hook, ent)
	end
end

hook.Add("Star_Trek.Sections.LocationChanged", "StarTrekEntities.DisableZones.LocationChanged", function(ply, old_deck, old_sectionId, new_deck, new_sectionId)
	DisableZones:SetPlayerLocation(ply, new_deck, new_sectionId)
end)

hook.Add("PlayerDisconnected", "StarTrekEntities.DisableZones.PlayerDisconnected", function(ply)
	DisableZones.PlayerLocations[ply] = nil
end)
