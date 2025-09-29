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
		if not ply or not ply:IsPlayer() then
			ply = player.GetAll()
		end

		net.Start("StarTrekEntities.StatusSync")
		if required_system then
			net.WriteTable({ [required_system] = self.Status[required_system] })
		else
			net.WriteTable({
				comms = self.Status.comms,
				gravity = self.Status.gravity,
				lifesupport = self.Status.lifesupport,
			})
			net.Send(ply)
		end
	end

	net.Receive("StarTrekEntities.StatusSync", function(len, ply)
		StarTrekEntities:SyncStatus(ply)
	end)
	function StarTrekEntities:SetStatus(syst, key, value)
		if not self[syst] then return end
		self[syst][key] = value
		StarTrekEntities:SyncStatus(nil, syst)
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
else
	function StarTrekEntities:SetStatus(syst, key, value)
		ErrorNoHaltWithStack("StarTrekEntities:SetStatus should not be called on the client!\n")
	end
	net.Receive("StarTrekEntities.StatusSync", function()
		local status = net.ReadTable()
		if not status then return end
		local required_system = net.ReadString()
		if required_system then
			if not StarTrekEntities.Status[required_system] then return end
			StarTrekEntities.Status[required_system] = status[required_system]
		else
			StarTrekEntities.Status = status
		end
	end)
end
function StarTrekEntities.Status:Get(syst, key)
	if not self[syst] then return nil end
	return self[syst][key]
end

function StarTrekEntities:GetStatus(syst)
	return self.Status[syst]
end


StarTrekEntities:Include("sv_fix_think.lua", "sv_")
StarTrekEntities:Include("sv_save_entities.lua", "sv_")
StarTrekEntities:Include("sv_communication_scramble.lua", "sv_")
StarTrekEntities:Include("sv_lifesupport_grav_think.lua", "sv_")