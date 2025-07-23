ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Author = "Void"

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.PrintName = "Communications Array"
ENT.Category = "Star Trek Entities"

ENT.Editable = true

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "PlayerRepairing" )
    self:NetworkVar( "String", 1, "CommsModel", {
        KeyName = "CommsModels",
        Edit = {
            type = "String",
            title = "Entity Model:",
			category = "Model Settings",
            waitforenter = true,
        }
    } )
    self:NetworkVar( "Int", 0, "CommsHealth", {
        KeyName = "CommsHealth",
        Edit = {
            type = "Int",
            title = "Entity Health:",
			category = "Health Settings",
            min = 200,
            max = 10000,
        }
    } )
	self:NetworkVar( "Bool", 1, "DisableComms", {
		KeyName = "DisableComms",
		Edit = {
			type = "Boolean",
			title = "Disable /comms",
			category = "Command Settings (When entity is destroyed.)",
			min = 0,
			max = 1,
		}
	} )
	self:NetworkVar( "Bool", 2, "DisableAdvert", {
		KeyName = "DisableAdvert",
		Edit = {
			type = "Boolean",
			title = "Disable /advert",
			category = "Command Settings (When entity is destroyed.)",
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
		self:SetCommsHealth( 200 )
		self:SetDisableComms( false )
		self:SetDisableAdvert( false )
		self:SetDisplayHealth( true )
	end
end
