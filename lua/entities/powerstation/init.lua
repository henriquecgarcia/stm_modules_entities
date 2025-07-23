AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
    self:SetModel( "models/props/starwars/tech/mainframe.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetHealth( 500 )
    self:SetMaxHealth( 500 )
	self:SetUseType( SIMPLE_USE )

    local PowerPhys = self:GetPhysicsObject()
    if IsValid( PowerPhys ) then
        PowerPhys:Wake()
    end
end

function ENT:CanProperty(ply, property)
    if !ply:IsAdmin() && property == "editentity" then
        return false
    end
end

function ENT:Use( ply )
if !IsValid( ply ) then return end
if !ply:IsPlayer() then return end
if !ply:IsAdmin() then return end
local CheckString = string.EndsWith( self:GetStationModel(), ".mdl" )
	self:SetHealth( self:GetStationHealth() )
	self:SetMaxHealth( self:GetStationHealth() )
	if CheckString then
		self:SetModel( self:GetStationModel() )
	end
	self:PhysicsInit( SOLID_VPHYSICS ) -- Redo physics since the model was changed...I guess.
end

local LightEntities = {
	["light"] = true,
	["light_spot"] = true,
	["light_dynamic"] = true,
}

function ENT:OnTakeDamage( dmg )
    self:TakePhysicsDamage( dmg )
    if ( self:Health() <= 0 ) then return end
    self:SetHealth( math.Clamp( self:Health() - dmg:GetDamage(), 0, self:GetMaxHealth() ) )
    if ( self:Health() <= 0 ) then
    local BoomBoom4 = ents.Create( "env_explosion" )
        BoomBoom4:SetKeyValue( "spawnflags", 144 )
        BoomBoom4:SetKeyValue( "iMagnitude", 15 )
        BoomBoom4:SetKeyValue( "iRadiusOverride", 256 )
        BoomBoom4:SetPos( self:GetPos() )
        BoomBoom4:Spawn()
        BoomBoom4:Fire( "explode", "", 0 )
        PrintMessage( HUD_PRINTCENTER, "Power Station has been destroyed!" )
        self:Ignite( 20, 250 )
		if self:GetLockDoors() then
			for k, door in pairs( ents.FindByClass( "func_door" ) ) do
				door:Input( "Lock" )
				door:Input( "Close" )
			end
		end
		if self:GetDisableLights() then
			for k, light in pairs( ents.GetAll() ) do
				if LightEntities[light:GetClass()] then
					light:Input( "TurnOff" )
				end
			end
		end
    end
end

function ENT:Think()
    if self:GetPlayerRepairing() then
        if self:Health() <= 0 then return end
        if self:Health() >= self:GetMaxHealth() then
            for k, ent in pairs( ents.GetAll() ) do 
				if ent:GetClass() == "func_door" then
					ent:Input( "Unlock" )
				elseif LightEntities[ent:GetClass()] then
					ent:Input( "TurnOn" )
				end
			end
        end
        self:SetPlayerRepairing( false )
    end
end

function ENT:OnRemove() -- This is here purely to stop all doors from staying locked if someone destroys the entity then removes it.
    for k, ent in pairs( ents.GetAll() ) do 
		if ent:GetClass() == "func_door" then
			ent:Input( "Unlock" )
		elseif LightEntities[ent:GetClass()] then
			ent:Input( "TurnOn" )
		end
	end
end
