AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self:SetModel( "models/ships/enterprise/wallmount_02.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_VPHYSICS )
	-- self:SetPos( self:GetPos() + Vector( 0, 0, 70 ) ) -- This spawns underground in some maps so set to 100 then DropToFloor().
	self:SetPos( self:GetPos() ) -- This spawns underground in some maps so set to 100 then DropToFloor().
	self:SetHealth( 500 )
	self:SetMaxHealth( 500 )
	self:SetUseType( SIMPLE_USE )
	-- self:DropToFloor()

	local owner = self:GetOwner()
	if table.Count( ents.FindByClass( "lifesupport" ) ) ~= 1 then
		for k, v in player.Iterator() do
			if not IsValid( v ) then continue end
			if v:IsAdmin() then
				v:ChatPrint( "Another life support system already exists. Please remove it before placing a new one." )
			end
		end
		self:Remove()
		return
	end

	local SuppPhys = self:GetPhysicsObject()
	if IsValid( SuppPhys ) then
		SuppPhys:Wake()
	end

	hook.Run( "OnLifeSupportCreated", self )

	self.Working = true

	local dmg_info = DamageInfo()

	self:UpdateScannerData()
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

function ENT:Use( ply )
	if !IsValid( ply ) then return end
	if !ply:IsPlayer() then return end
	if !ply:IsAdmin() then return end
	local CheckString = string.EndsWith( self:GetLifeModel(), ".mdl" )
	if CheckString then
		self:SetModel( self:GetLifeModel() )
	end
	self:PhysicsInit( SOLID_VPHYSICS ) -- Redo physics since the model was changed...I guess.
end

function ENT:OnTakeDamage( dmg )
	self:TakePhysicsDamage( dmg )
	if ( self:Health() <= 0 ) then return end
	self:SetHealth( math.Clamp( self:Health() - dmg:GetDamage(), 0, self:GetMaxHealth() ) )
	self.last_hit_location = dmg:GetDamagePosition()
	print( "Last hit location updated." .. tostring(self.last_hit_location) )
	self:UpdateScannerData()

	hook.Run( "OnLifeSupportDamage", self, dmg )

	if ( self:Health() <= 0 ) then

		local BoomBoom2 = ents.Create( "env_explosion" )
		BoomBoom2:SetKeyValue( "spawnflags", 144 )
		BoomBoom2:SetKeyValue( "iMagnitude", 15 )
		BoomBoom2:SetKeyValue( "iRadiusOverride", 256 )
		BoomBoom2:SetPos( self:GetPos() )
		BoomBoom2:Spawn()
		BoomBoom2:Fire( "explode", "", 0 )

		PrintMessage( HUD_PRINTCENTER, "Life Support System has been destroyed!" )

		self:Ignite( 20, 250 )

		self.Working = false

		hook.Run( "OnLifeSupportDestroyed", self )
	end
end

function ENT:UpdateScannerData()
	local health = self:Health()
	local maxHealth = self:GetMaxHealth()

	local status = health > 0 and "Active" or "Destroyed"

	local fun_message = ""
	if health <= 0 then
		fun_message = "System is offline. Please repair."
	elseif health < maxHealth * 0.25 then
		fun_message = "Warning: System health is critically low! Failure imminent!"
	elseif health < maxHealth * 0.5 then
		fun_message = "Caution: System health is below 50%. Consider repairs."
	elseif health < maxHealth * 0.75 then
		fun_message = "System health is below 75%. Monitor closely."
	else
		fun_message = "System is operational."
	end

	self.ScannerData = "Status: " .. status .. "\n" .. fun_message .. "\n"

end

local last_shock_time = 0
local last_damage_time = 0
function ENT:DoDamage(ply)
	if not IsValid( ply ) then return end
	if not ply:IsPlayer() then return end

	-- ENT, ply, section, deck
	local should_damage = hook.Run( "ShouldIgnoreLifeSupportDamagePlayer", self, ply, nil, nil )
	if should_damage == true then return end

	local pMovement = ply:GetMoveType()
	if pMovement == MOVETYPE_NOCLIP or pMovement == MOVETYPE_OBSERVER then return end

	local dmg = DamageInfo()
	dmg:SetDamage( self:GetDamageAmount() )
	dmg:SetDamageType( DMG_RADIATION )
	dmg:SetAttacker( self )
	dmg:SetInflictor( self )

	ply:TakeDamageInfo( dmg )
end

function ENT:Think()
	local health = self:Health()
	local maxHealth = self:GetMaxHealth()
	if health >= maxHealth then
		if self.ShockEnt and IsValid( self.ShockEnt ) then
			self.ShockEnt:Remove()
			self.ShockEnt = nil
		end
		return -- Don't care if health is at max.
	end
	if not self.ShockEnt or not IsValid( self.ShockEnt ) then
		local shockEnt = ents.Create( "pfx4_05~" )
		shockEnt:SetPos( self:GetPos() )
		shockEnt:SetAngles( self:GetAngles() )
		shockEnt:SetParent( self )
		shockEnt:Spawn()
		self.ShockEnt = shockEnt
	end
	if health <= 0 then
		if self:GetDisableSupport() then
			if last_damage_time + self:GetDamageSeconds() > CurTime() then return end -- Don't apply damage if not time yet.
			last_damage_time = CurTime()
			for k, v in player.Iterator() do
				self:DoDamage( v )
			end
		end
	end
	if self:GetPlayerRepairing() then
		if not self.Working then
			hook.Run( "OnLifeSupportRepaired", self )
			self.Working = true
		end
		self:SetPlayerRepairing( false )
	end

	local hp_percent = health / maxHealth
	local time_interval = 60 * ( hp_percent ) -- Calculate time interval based on health percentage

	time_interval = math.Clamp( time_interval, 5, 60 ) -- Ensure the interval is between 5 and 60 seconds

	if last_shock_time + time_interval < CurTime() then
		last_shock_time = CurTime()
		self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 75, 100, 0.5 )
	end
end

function ENT:OnRemove()
	hook.Run( "OnLifeSupportRemoved", self )
end
