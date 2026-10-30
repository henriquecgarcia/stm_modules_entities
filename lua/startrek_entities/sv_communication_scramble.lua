StarTrekEntities = StarTrekEntities or {}
StarTrekEntities.Comms = StarTrekEntities.Comms or {}
print("StarTrekEntities: Loaded sv_communication_scramble.lua")
-- Define combining characters (Zalgo style)
local zalgo_up = {"̍","̎","̄","̅","̿","̑","̆","̐","͒","͗","͑","̇","̈","̊","͂","̓","̈́","͊","͋","͌","̃","̂","̌","͐"}
local zalgo_mid = {"̕","̛","̀","́","͘","̡","̢","̧","̨","̴","̵","̶","͜","͝","͞","͟","͠","͢","̸","̷","͡"}
local zalgo_down = {"̖","̗","̘","̙","̜","̝","̞","̟","̠","̤","̥","̦","̩","̪","̫","̬","̭","̮","̯","̰","̱","̲","̳","̹","̺","̻","̼","ͅ","͇","͈","͉","͍","͎","͓","͔","͕","͖","͙","͚"}

-- Scramble text with intensity level (1–6)
math.randomseed(os.time())

function StarTrekEntities.Comms:ScrambleText(text, intensity)
	if not text or text == "" then return "" end
	if intensity == 0 then return text end

	intensity = math.Clamp(intensity or 0, 1, 6)
	local random = math.random

	local function appendRandom(out, tbl, count)
		for i = 1, count do
			out[#out + 1] = tbl[random(#tbl)]
		end
	end

	local result = {}
	for i = 1, #text do
		local char = text:sub(i, i)
		if char:match("%s") then
			result[#result + 1] = char
		else
			result[#result + 1] = char
			appendRandom(result, zalgo_up, intensity)
			appendRandom(result, zalgo_mid, math.max(0, intensity - 2))
			appendRandom(result, zalgo_down, intensity)
		end
	end

	return table.concat(result)
end

hook.Add("CommunicationsArrayInitialized", "ActivateCommsSystem", function(ent)
	if not IsValid(ent) then return end
	StarTrekEntities:SetSystemStatus("comms", {
		active = true,
		scrambled_level = 0,
	})
end)

hook.Add("CommunicationsArrayDamaged", "HandleCommsDamage", function(ent, dmg, damage_level)
	if not IsValid(ent) then return end
	StarTrekEntities:SetStatus("comms", "scrambled_level", damage_level)
end)

hook.Add("CommunicationsArrayRepairing", "HandleCommsRepairing", function(ent, intensity)
	if not IsValid(ent) then return end

	StarTrekEntities:SetSystemStatus("comms", {
		active = true,
		scrambled_level = intensity,
	})
end)

hook.Add("CommunicationsArrayRemoved", "DeactivateCommsSystem", function(ent, aux)
	if not IsValid(ent) then return end
	StarTrekEntities:SetSystemStatus("comms", {
		active = false,
		scrambled_level = 0,
	})
end)

hook.Add("PlayerSay", "ScrambleChat", function(ply, text)
	local EGM = GAMEMODE or GM or {}
	if (EGM.Name or "") == "Star Trek RP" then return end -- Don't interfere with EGM Star Trek RP
	if EGM.AcceptEULA == true then return end -- Don't interfere with EGM (I think...)
	if text:sub(1, 1) ~= "/" then return end -- Not my thing

	text = text:sub(2)
	local command, message = text:match("^(%S+)%s*(.*)$")
	local comms_status = StarTrekEntities.Status.comms or {active = false, scrambled_level = 0}
	if command == "comms" then
		if not comms_status.active then
			ply:ChatPrint("Communications Array is not active.")
			return ""
		end
		if not message or message == "" then
			ply:ChatPrint("Usage: /comms <message>")
			return ""
		end
		local intensity = comms_status.scrambled_level or 0
		local scrambled_message = StarTrekEntities.Comms:ScrambleText(message, intensity)
		local speaker = "[Comms] " .. ply:Nick()
		BroadcastLua("chat.AddText(Color(255, 0, 0), " .. string.format("%q", speaker) .. ", Color(255, 255, 255), " .. string.format("%q", ": " .. scrambled_message) .. ")")
		return ""
	end
end)
