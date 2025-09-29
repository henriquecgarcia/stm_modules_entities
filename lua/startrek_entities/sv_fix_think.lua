print("StarTrekEntities: Loaded sv_fix_think.lua")
local valid_ents = {
	["lifesupport"] = true,
	["commsarray"] = true,
	["gravgen"] = true,
}

local last_think = 0

hook.Add("Star_Trek.tools.sonic_driver.trace_hit", "Valid_Ents_Fix_Trace", function (owner, wep, hit_ent, hit_pos)
	if not IsValid(hit_ent) or not IsValid(owner) or not owner:IsPlayer() then return end -- Don't care, not a player or not a valid entity, just return

	local ent_class = hit_ent:GetClass()

	if not valid_ents[ent_class] then return end -- If the entity is not in the valid list, just return

	local now = CurTime()
	if now < last_think + 1 then return end
	last_think = now
	local hp = hit_ent:Health()
	local max_hp = hit_ent:GetMaxHealth()
	if hp >= max_hp then return end
	math.randomseed(os.time() + hit_ent:EntIndex())
	local repair_amount = math.random(15, 30)
	hit_ent:SetHealth(math.Clamp(hp + repair_amount, 0, max_hp))
	hit_ent:SetPlayerRepairing(true)
	
	if hit_ent:Health() >= hit_ent:GetMaxHealth() then
		wep:SetSkin(1)
		return false
	end

	return true

end)