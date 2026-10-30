AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
	local disable_zones = StarTrekEntities.DisableZones
	if not disable_zones then
		self:Remove()
		return
	end

	disable_zones:InitializeEntity(self, {
		system = "gravity",
		scope = "deck",
		model = "models/maxofs2d/hover_rings.mdl",
		color = Color(255, 0, 0, 255),
		name = "DisableGravity",
		created_hook = "OnDisableGravityDeckCreated",
	})
end


function ENT:OnRemove()
	local disable_zones = StarTrekEntities.DisableZones
	if disable_zones then
		disable_zones:RemoveEntity(self, "OnDisableGravityDeckRemoved")
	end
end

function ENT:CanProperty(ply, property)
	if !ply:IsAdmin() && property == "editentity" then
		return false
	end
end
function ENT:CanTool(ply, tool)
	if tool == "remover" then
		return true
	end
	if tool == "permaprops" then
		return false
	end
end
