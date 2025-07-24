---------------------------------------
---------------------------------------
--   This file is protected by the   --
--	   MIT License.		 --
--				   --
--   See LICENSE for full		 --
--   license details.			--
---------------------------------------
---------------------------------------

---------------------------------------
--	 sonic driver | Shared	 --
---------------------------------------

SWEP.Base = "oni_base"

SWEP.PrintName = "Sonic Driver [Fixing Tool]"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3
SWEP.SlotPos = 0

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/crazycanadian/startrek/tools/sonicdriver.mdl"

SWEP.HoldType = "pistol"

SWEP.BoneManip = {
	["ValveBiped.clip"] = {
		Pos = Vector(-100, 0, 0),
	},
	["ValveBiped.base"] = {
		Pos = Vector(-100, 0, 0),
	},
	["ValveBiped.square"] = {
		Pos = Vector(-100, 0, 0),
	},
	["ValveBiped.hammer"] = {
		Pos = Vector(-100, 0, 0),
	},
	["ValveBiped.Bip01_R_Finger01"] = {
		Ang = Angle(-50, 0, 0)
	},
	["ValveBiped.Bip01_R_Finger1"] = {
		Ang = Angle(-20, -20, 0)
	},
	["ValveBiped.Bip01_R_Forearm"] = {
		Pos = Vector(-10, 0, 0),
	},
	["ValveBiped.Bip01_R_Clavicle"] = {
		Pos = Vector(-1, 0, 0),
		Ang = Angle(0, 0, 15)
	},
}

SWEP.CustomViewModel = "models/crazycanadian/startrek/tools/sonicdriver.mdl"
SWEP.CustomViewModelBone = "ValveBiped.Bip01_R_Hand"
SWEP.CustomViewModelOffset = Vector(4, -2, -0.7)
SWEP.CustomViewModelAngle = Angle(-20, 180, -140)
SWEP.CustomViewModelScale = 1

SWEP.CustomDrawWorldModel = true
SWEP.CustomWorldModelBone = "ValveBiped.Bip01_R_Hand"
SWEP.CustomWorldModelOffset = Vector(4.5, -1.5, -1.1)
SWEP.CustomWorldModelAngle = Angle(-40, 180, 180)
SWEP.CustomWorldModelScale = 1

SWEP.lastReload = 0

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Active")
end

function SWEP:InitializeCustom()
	self:SetDeploySpeed(20)
	self:SetActive(false)
end

local working_ents = {
	["commsarray"] = true,
	["lifesupport"] = true,
	["gravgen"] = true,
}

function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end

    local trace = owner:GetEyeTrace()
    local ent = trace.Entity
    if not IsValid(ent) or not working_ents[ent:GetClass()] then return end

    if not self:GetActive() then
        self:TurnOn()
    end

    -- Do something with the valid entity
    local hp = ent:Health()
    local max_hp = ent:GetMaxHealth()
    if max_hp <= hp then
        -- Already at max health, do nothing, maybe notify the player via a audio failure sound, idk
        return
    end

    math.randomseed(os.time() + ent:EntIndex())
    local repair_amount = math.random(15, 30)
    ent:SetHealth(math.Clamp(hp + repair_amount, 0, max_hp))
    ent:SetPlayerRepairing(true)
    self.LoopId = self:StartLoopingSound("star_trek.sonic_driver_loop")
    self:SetSkin(2)
end

local last_think_fix = 0
function SWEP:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end
    if not self:GetActive() then return end
    if not isnumber(self.LoopId) then
        if self:GetSkin() ~= 1 then
            self:SetSkin(1) -- Reset skin if not active
        end
        return
    end
    local trace = owner:GetEyeTrace()
    local ent = trace.Entity
    if not IsValid(ent) or not working_ents[ent:GetClass()] then
        if isnumber(self.LoopId) then
            self:StopLoopingSound(self.LoopId)
            self:EmitSound("guusconl/startrek/tng_fed_engidevice_end_01.mp3")
            self.LoopId = nil
        end
        self:SetSkin(1)
        return
    end
    local now = CurTime()
    if now < last_think_fix + 1 then return end
    last_think_fix = now
    if isnumber(self.LoopId) then
        local hp = ent:Health()
        local max_hp = ent:GetMaxHealth()
        math.randomseed(os.time() + ent:EntIndex())
        local repair_amount = math.random(15, 30)
        ent:SetHealth(math.Clamp(hp + repair_amount, 0, max_hp))
        ent:SetPlayerRepairing(true)
        if ent:Health() >= ent:GetMaxHealth() then
            self:StopLoopingSound(self.LoopId)
            self:EmitSound("guusconl/startrek/tng_fed_engidevice_end_01.mp3")
            self.LoopId = nil
            self:SetSkin(1)
        end
    end
end

function SWEP:Reload()
	if not IsFirstTimePredicted() then return end
    if CurTime() < self.lastReload + 0.5 then return end
    self.lastReload = CurTime()

	if self:GetActive() then
		self:TurnOff()
	else
		self:TurnOn()
	end
end

function SWEP:TurnOn()
	-- self.LoopId = self:StartLoopingSound("star_trek.sonic_driver_loop")
    self:EmitSound("guusconl/startrek/tng_fed_beep_04.mp3")
	self:SetSkin(1)
    self:SetActive(true)
end

function SWEP:TurnOff()
	if isnumber(self.LoopId) then
		self:StopLoopingSound(self.LoopId)
		self:EmitSound("guusconl/startrek/tng_fed_engidevice_end_01.mp3")
		self.LoopId = nil
	end
    self:EmitSound("guusconl/startrek/tng_fed_beep_04.mp3")
    -- self:SendWeaponAnim(ACT_VM_IDLE)
	self:SetSkin(0)
	self:SetActive(false)
end

function SWEP:OnRemove()
    self:TurnOff()
end
function SWEP:OnDrop()
    self:OnRemove()
end
function SWEP:OnHolster()
    self:OnRemove()
end