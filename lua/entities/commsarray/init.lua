AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

local AllowComms = false

function ENT:Initialize()
    self:SetModel( "models/props/starwars/tech/imperial_deflector_sky.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetHealth( 500 )
    self:SetMaxHealth( 500 )
    self:SetUseType( SIMPLE_USE )

    local CommPhys = self:GetPhysicsObject()
    if IsValid( CommPhys ) then
        CommPhys:Wake()
    end
end

hook.Add( "PlayerSay", "DisableComms", function( ply, txt ) 
    for k, v in pairs( ents.FindByClass( "commsarray" ) ) do
        if v:Health() > 0 then
			AllowComms = true
			break
		end
		if v:GetDisableComms() then
			if string.sub( txt, 1, 6 ) == "/comms" then
				return ""
			end
		end
		if v:GetDisableAdvert() then
			if string.sub( txt, 1, 7 ) == "/advert" then
				return ""
			end
		end
		v:SetPlayerRepairing( false )
    end
end )

function ENT:CanProperty(ply, property)
    if !ply:IsAdmin() && property == "editentity" then
        return false
    end
end

function ENT:Use( ply )
if !IsValid( ply ) then return end
if !ply:IsPlayer() then return end
if !ply:IsAdmin() then return end
local CheckString = string.EndsWith( self:GetCommsModel(), ".mdl" )
    self:SetHealth( self:GetCommsHealth() )
    self:SetMaxHealth( self:GetCommsHealth() )
	if CheckString then
		self:SetModel( self:GetCommsModel() )
	end
    self:PhysicsInit( SOLID_VPHYSICS ) -- Redo physics since the model was changed...I guess.
end

function ENT:OnTakeDamage( dmg )
    self:TakePhysicsDamage( dmg )
    if ( self:Health() <= 0 ) then return end
    self:SetHealth( math.Clamp( self:Health() - dmg:GetDamage(), 0, self:GetMaxHealth() ) )
    if self:Health() <= 0 then
    local BoomBoom3 = ents.Create( "env_explosion" )
        BoomBoom3:SetKeyValue( "spawnflags", 144 )
        BoomBoom3:SetKeyValue( "iMagnitude", 15 )
        BoomBoom3:SetKeyValue( "iRadiusOverride", 256 )
        BoomBoom3:SetPos( self:GetPos() )
        BoomBoom3:Spawn()
        BoomBoom3:Fire( "explode", "", 0 )
        PrintMessage( HUD_PRINTCENTER, "Communications Array has been destroyed!" )
        self:Ignite( 20, 250 )
		AllowComms = false
        self:SetPlayerRepairing( false )
    end
end

function ENT:OnRemove()
    AllowComms = true
end