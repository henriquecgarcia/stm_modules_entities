StarTrekEntities.Status = StarTrekEntities.Status or {
	comms = {
		active = false,
		scrambled_level = 0,
	},
	gravity = {
		active = false,
	},
	lifesupport = {
		active = false,
	},
}

if SERVER then
	util.AddNetworkString("StarTrekEntities.StatusSync")

	function StarTrekEntities:SyncStatus(ply, required_system)
		local recipients = ply
		if not IsValid(recipients) or not recipients:IsPlayer() then
			recipients = player.GetAll()
		end

		local status = self.Status
		local payload
		if required_system then
			if not status[required_system] then return end
			payload = { [required_system] = status[required_system] }
		else
			payload = {
				comms = status.comms,
				gravity = status.gravity,
				lifesupport = status.lifesupport,
			}
		end

		net.Start("StarTrekEntities.StatusSync")
		net.WriteTable(payload)
		net.Send(recipients)
	end

	net.Receive("StarTrekEntities.StatusSync", function(len, ply)
		StarTrekEntities:SyncStatus(ply)
	end)

	function StarTrekEntities:SetStatus(syst, key, value)
		if not self.Status[syst] then return end
		if self.Status[syst][key] == value then return end
		self.Status[syst][key] = value
		self:SyncStatus(nil, syst)
	end

	function StarTrekEntities:SetSystemStatus(syst, values)
		if not self.Status[syst] or not values then return end

		local changed = false
		for key, value in pairs(values) do
			if self.Status[syst][key] ~= value then
				self.Status[syst][key] = value
				changed = true
			end
		end

		if changed then
			self:SyncStatus(nil, syst)
		end
	end

	hook.Add("OnLifeSupportCreated", "StarTrekEntities.LifeSupportStatus", function(ent)
		if not IsValid(ent) then return end
		StarTrekEntities:SetStatus("lifesupport", "active", true)
	end)
	hook.Add("OnLifeSupportRemoved", "StarTrekEntities.LifeSupportStatus", function(ent)
		if not IsValid(ent) then return end
		StarTrekEntities:SetStatus("lifesupport", "active", false)
	end)
	hook.Add("OnLifeSupportDestroyed", "StarTrekEntities.LifeSupportStatus", function(ent)
		if not IsValid(ent) then return end
		StarTrekEntities:SetStatus("lifesupport", "active", false)
	end)
	hook.Add("OnLifeSupportRepaired", "StarTrekEntities.LifeSupportStatus", function(ent)
		if not IsValid(ent) then return end
		StarTrekEntities:SetStatus("lifesupport", "active", true)
	end)

	hook.Add("OnGravGenInitialized", "StarTrekEntities.GravityStatus", function(ent)
		if not IsValid(ent) then return end
		StarTrekEntities:SetStatus("gravity", "active", true)
	end)
	hook.Add("OnGravGenRemoved", "StarTrekEntities.GravityStatus", function(ent)
		if not IsValid(ent) then return end
		StarTrekEntities:SetStatus("gravity", "active", false)
	end)
	hook.Add("OnGravGenDestroyed", "StarTrekEntities.GravityStatus", function(ent)
		if not IsValid(ent) then return end
		StarTrekEntities:SetStatus("gravity", "active", false)
	end)
	hook.Add("OnGravGenRepaired", "StarTrekEntities.GravityStatus", function(ent)
		if not IsValid(ent) then return end
		StarTrekEntities:SetStatus("gravity", "active", true)
	end)

	hook.Add("PlayerInitialSpawn", "StarTrekEntities.SyncStatus", function(ply)
		StarTrekEntities:SyncStatus(ply)
	end)
else
	function StarTrekEntities:SetStatus(syst, key, value)
		ErrorNoHaltWithStack("StarTrekEntities:SetStatus should not be called on the client!\n")
	end
	net.Receive("StarTrekEntities.StatusSync", function()
		local status = net.ReadTable()
		if not status then return end

		for syst, data in pairs(status) do
			if StarTrekEntities.Status[syst] then
				StarTrekEntities.Status[syst] = data
			end
		end
	end)
end

function StarTrekEntities:GetStatus(syst, key, default)
	if game.GetMap() ~= "rp_intrepid_v1" then return key == "active" or default end
	if not self.Status[syst] then
		return default
	end
	local value = self.Status[syst][key]
	if value == nil then
		return default
	end
	return value
end


StarTrekEntities:Include("sv_fix_think.lua", "sv_")
StarTrekEntities:Include("sv_save_entities.lua", "sv_")
StarTrekEntities:Include("sv_disable_zones.lua", "sv_")
StarTrekEntities:Include("sv_communication_scramble.lua", "sv_")
StarTrekEntities:Include("sv_lifesupport_grav_think.lua", "sv_")
