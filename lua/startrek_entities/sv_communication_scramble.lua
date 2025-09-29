StarTrekEntities = StarTrekEntities or {}
StarTrekEntities.Comms = StarTrekEntities.Comms or {}
print("StarTrekEntities: Loaded sv_communication_scramble.lua")
-- Define combining characters (Zalgo style)
local zalgo_up = {"̍","̎","̄","̅","̿","̑","̆","̐","͒","͗","͑","̇","̈","̊","͂","̓","̈́","͊","͋","͌","̃","̂","̌","͐"}
local zalgo_mid = {"̕","̛","̀","́","͘","̡","̢","̧","̨","̴","̵","̶","͜","͝","͞","͟","͠","͢","̸","̷","͡"}
local zalgo_down = {"̖","̗","̘","̙","̜","̝","̞","̟","̠","̤","̥","̦","̩","̪","̫","̬","̭","̮","̯","̰","̱","̲","̳","̹","̺","̻","̼","ͅ","͇","͈","͉","͍","͎","͓","͔","͕","͖","͙","͚"}

-- Scramble text with intensity level (1–6)
function StarTrekEntities.Comms:ScrambleText(text, intensity)
	if not text or text == "" then return "" end
	if intensity == 0 then return text end
	math.randomseed(os.time()) -- Seed random number generator
	intensity = math.Clamp(intensity, 1, 6) -- Ensure intensity is between 1 and 6
	local function getRandom(tbl, count)
		local out = ""
		for i = 1, count do
			out = out .. tbl[math.random(#tbl)]
		end
		return out
	end

	local result = ""
	for i = 1, #text do
		local char = text:sub(i, i)
		if char:match("%s") then
			result = result .. char -- don't glitch spaces
		else
			local up = getRandom(zalgo_up, intensity)
			local mid = getRandom(zalgo_mid, math.max(0, intensity - 2))
			local down = getRandom(zalgo_down, intensity)
			result = result .. char .. up .. mid .. down
		end
	end

	return result
end

local comms_status = {
	active = false,
	scrambled_level = 0,
}

hook.Add("CommunicationsArrayInitialized", "ActivateCommsSystem", function(ent)
	if not IsValid(ent) then return end
	StarTrekEntities:SetStatus("comms", "active", true)
	StarTrekEntities:SetStatus("comms", "scrambled_level", 0)
end)

hook.Add("CommunicationsArrayDamaged", "HandleCommsDamage", function(ent, dmg, damage_level)
	if not IsValid(ent) then return end
	StarTrekEntities:SetStatus("comms", "scrambled_level", damage_level)
end)

hook.Add("CommunicationsArrayRepairing", "HandleCommsRepairing", function(ent, intensity)
	if not IsValid(ent) then return end

	StarTrekEntities:SetStatus("comms", "scrambled_level", intensity)

	StarTrekEntities:SetStatus("comms", "active", true) -- Assume repairing means the system is still active
end)

hook.Add("CommunicationsArrayRemoved", "DeactivateCommsSystem", function(ent, aux)
	if not IsValid(ent) then return end
	StarTrekEntities:SetStatus("comms", "active", false)
	StarTrekEntities:SetStatus("comms", "scrambled_level", 0)
end)

hook.Add("PlayerSay", "ScrambleChat", function(ply, text)
	local EGM = GAMEMODE or GM
	if (EGM.Name or "") == "Star Trek RP" then return end -- Don't interfere with EGM Star Trek RP
	if EGM.AcceptEULA == true then return end -- Don't interfere with EGM (I think...)
	if text[1] ~= "/" then return end -- Not my thing
	text = text:sub(2) -- Remove the slash
	local args = string.Explode(" ", text)
	local comms_status = StarTrekEntities.Status.comms or {active = false, scrambled_level = 0}
	if args[1] == "comms" then
		if not comms_status.active then
			ply:ChatPrint("Communications Array is not active.")
			return ""
		end
		if #args < 2 then
			ply:ChatPrint("Usage: /comms <message>")
			return ""
		end
		local message = table.concat(args, " ", 2)
		if not message or message == "" then
			ply:ChatPrint("Please provide a message to scramble.")
			return ""
		end
		local intensity = comms_status.scrambled_level or 0
		local scrambled_message = StarTrekEntities.Comms.ScrambleText(message, intensity)
		BroadcastLua("chat.AddText(Color(255, 0, 0), '[Comms] " .. ply:Nick() .. "', Color(255, 255, 255), ': " .. scrambled_message .. "')")
		return ""
	end
end)