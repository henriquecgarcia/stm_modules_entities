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
	self.Section = section
	if not success then
		print( "Failed to determine section for DisableLifeSupport entity at position: " .. tostring(self:GetPos()) )
		self:Remove()
		return
	end


	hook.Run( "OnDisableLifeSupportCreated", self, deck, section )
end


function ENT:OnRemove()
	hook.Run( "OnDisableLifeSupportRemoved", self, self.Deck, self.Section )
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

-- local section_overwatch = {}
-- hook.Add("Star_Trek.Sections.LocationChanged", "DisableLifeSupport", function( ply, old_deck, old_section, new_deck, new_section )
-- 	if not IsValid( ply ) or not ply:IsPlayer() then return end
-- end )

function ENT:DoDamage( ply, section, deck )
	if not IsValid( ply ) then return end
	if not ply:IsPlayer() then return end
	local inSection = Star_Trek.Sections:IsInSection( deck, section, ply:GetPos() )
	if self:GetEntireDeck() then
		inSection = Star_Trek.Sections:IsOnDeck( deck, ply:GetPos() )
	end
	if not inSection then return end

	local should_damage = hook.Run( "ShouldIgnoreLifeSupportDamagePlayer", self, ply, section, deck )
	if should_damage == true then return end

	local dmg = DamageInfo()
	dmg:SetDamage( self:GetDamageAmount() )
	dmg:SetDamageType( DMG_RADIATION )
	dmg:SetAttacker( self )
	dmg:SetInflictor( self )

	ply:TakeDamageInfo( dmg )
end
function ENT:RunDamages(sucess, deck, section)
	if sucess then
		-- if v:GetModel() == "models/player/startrek_female_spacesuit.mdl" then return end
		for k, v in player.Iterator() do
			self:DoDamage( v, section, deck )
		end
	else
		local range_entities = ents.FindInSphere( self:GetPos(), 1000 )
		for k, v in ipairs( range_entities ) do
			self:DoDamage( v, section, deck )
		end
	end
end

local last_damage_time = 0

function ENT:Think()
	local cur_time = CurTime()
	if cur_time - last_damage_time >= self:GetDamageSeconds() then
		last_damage_time = cur_time

		local dmg = DamageInfo()
		dmg:SetDamage( self:GetDamageAmount() )
		dmg:SetDamageType( DMG_RADIATION )
		dmg:SetAttacker( self )
		dmg:SetInflictor( self )
		local sucess, deck, section = Star_Trek.Sections:DetermineSection( self:GetPos() )
		self:RunDamages(sucess, deck, section)
	end
	self:NextThink( cur_time )
	return true
end
