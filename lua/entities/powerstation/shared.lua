ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Author = "Tood."

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.PrintName = "Power Station"
ENT.Category = "Tood's SWRP Entities"

ENT.Editable = true

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "PlayerRepairing" )
	self:NetworkVar( "String", 0, "StationModel", {
		KeyName = "StationModel",
		Edit = {
			type = "String",
			title = "Entity Model:",
			category = "Model Settings",
			waitforenter = true,
		}
	} )
	self:NetworkVar( "Int", 0, "StationHealth", {
		KeyName = "StationHealth",
		Edit = {
			type = "Int",
			title = "Entity Health:",
			category = "Health Settings",
			min = 200,
			max = 10000,
		}
	} )
	self:NetworkVar( "Bool", 1, "LockDoors", {
		KeyName = "LockDoors",
		Edit = {
			type = "Boolean",
			title = "Lock Doors",
			category = "Map Settings (When entity is destroyed.)",
			min = 0,
			max = 1,
		}
	} )
	self:NetworkVar( "Bool", 2, "DisableLights", {
		KeyName = "DisableLights",
		Edit = {
			type = "Boolean",
			title = "Disable Lights",
			category = "Map Settings (When entity is destroyed.)",
			min = 0,
			max = 1,
		}
	} )
	self:NetworkVar( "Bool", 3, "DisplayHealth", {
		KeyName = "DisplayHealth",
		Edit = {
			type = "Boolean",
			title = "Display Health Bar",
			min = 0,
			max = 1,
		}
	} )
	
	if SERVER then
		self:SetStationHealth( 200 )
		self:SetLockDoors( false )
		self:SetDisableLights( false )
		self:SetDisplayHealth( true )
	end
end
