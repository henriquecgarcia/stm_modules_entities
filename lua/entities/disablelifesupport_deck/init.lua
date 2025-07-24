AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:Initialize()
	self:SetModel( "models/props_junk/trafficcone001a.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self:SetPos( self:GetPos() + Vector( 0, 0, 70 ) ) -- This spawns underground in some maps so set to 100 then DropToFloor().
	self:DropToFloor()

	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:Wake()
	end

	local success, deck, section = Star_Trek.Sections:DetermineSection( self:GetPos() )
	self.Deck = deck
	if not success then
		for k, v in player.Iterator() do
			if not IsValid( v ) then continue end
			if v:IsAdmin() then
				v:ChatPrint( "You can't place this entity here. It's not a valid location." )
			end
		end
		print( "Failed to determine section for DisableLifeSupport entity at position: " .. tostring(self:GetPos()) )
		print( "You can't have this entity in space") --  #TODO: Make this a notification! people can't read prints
		self:Remove()
		return
	end

	hook.Run( "OnDisableLifeSupportDeckCreated", self )
end


function ENT:OnRemove()
	if not self.Deck then
		return
	end
	hook.Run( "OnDisableLifeSupportDeckRemoved", self )
end

function ENT:CanProperty(ply, property)
	if !ply:IsAdmin() && property == "editentity" then
		return false
	end
end
function ENT:CanTool(ply, tool)
	if tool == "permaprops" then
		return false
	end
end