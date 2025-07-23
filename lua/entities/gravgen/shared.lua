ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Author = "Void"

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.PrintName = "Gravity Generator"
ENT.Category = "Star Trek Entities"

ENT.Editable = true

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "PlayerRepairing" )
    self:NetworkVar( "String", 1, "GravModel", {
        KeyName = "GravModel",
        Edit = {
            type = "String",
            title = "Entity Model:",
			category = "Model Settings",
            waitforenter = true,
        }
    } )
    self:NetworkVar( "Int", 2, "GravHealth", {
        KeyName = "GravHealth",
        Edit = {
            type = "Int",
            title = "Entity Health:",
			category = "Health Settings",
            min = 200,
            max = 10000,
        }
    } )
	self:NetworkVar( "Bool", 1, "DisableGrav", {
		KeyName = "DisableGrav",
		Edit = {
			type = "Boolean",
			title = "Disable Gravity",
			category = "Server/Player Settings (When entity is destroyed.)",
			min = 0,
			max = 1,
		}
	} )
	self:NetworkVar( "Bool", 2, "DisableFric", {
		KeyName = "DisableFric",
		Edit = {
			type = "Boolean",
			title = "Disable Friction",
			category = "Server/Player Settings (When entity is destroyed.)",
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
		self:SetGravHealth( 200 )
		self:SetDisableGrav( true )
		self:SetDisableFric( true )
		self:SetDisplayHealth( true )
	end
end
