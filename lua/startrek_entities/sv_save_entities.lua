StarTrekEntities = StarTrekEntities or {}
StarTrekEntities.Data = StarTrekEntities.Data or {}

print("StarTrekEntities: Loaded sv_save_entities.lua")

local function CreateSQLTable()
	if sql.TableExists( "star_trek_entities" ) then return end

	sql.Query( [[
		CREATE TABLE star_trek_entities (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			ent_class TEXT NOT NULL,
			ent_model TEXT NOT NULL,
			ent_pos TEXT NOT NULL,
			data TEXT
		)
	]] )
end

StarTrekEntities.Data.CreateSQLTable = CreateSQLTable

local function DecodeEntityTransform(raw_pos)
	local decoded = util.JSONToTable(raw_pos or "")
	if not decoded then return end

	local pos_data = decoded.pos or decoded[1]
	local ang_data = decoded.ang or decoded[2]
	if not pos_data or not ang_data then return end

	return {
		pos = Vector(pos_data[1], pos_data[2], pos_data[3]),
		ang = Angle(ang_data[1], ang_data[2], ang_data[3])
	}
end

local function SelectSQLData( ent )
	if not IsValid( ent ) then return end

	if ent.SQL_ID then
		local by_id = sql.QueryRow( "SELECT * FROM star_trek_entities WHERE id = " .. sql.SQLStr( ent.SQL_ID ) )
		if by_id then
			by_id.data = util.JSONToTable( by_id.data or "" ) or {}
			by_id.ent_pos = DecodeEntityTransform( by_id.ent_pos )
			return by_id
		end
	end

	local result = sql.QueryRow( "SELECT * FROM star_trek_entities WHERE ent_class = " .. sql.SQLStr( ent:GetClass() ) .. " AND ent_model = " .. sql.SQLStr( ent:GetModel() or "" ) )
	if not result then return end

	result.data = util.JSONToTable( result.data or "" ) or {}
	result.ent_pos = DecodeEntityTransform( result.ent_pos )
	if not result.ent_pos then
		print( "Failed to decode position for entity: " .. ent:GetClass() .. " with model: " .. ent:GetModel() )
	end

	return result
end
function StarTrekEntities.Data:SelectSQLData( ent )
	return SelectSQLData( ent )
end

local function RemoveSQLData( ent )
	if not IsValid( ent ) then return end

	if ent.SQL_ID then
		sql.Query( "DELETE FROM star_trek_entities WHERE id = " .. sql.SQLStr( ent.SQL_ID ) )
		ent.SQL_ID = nil
		return
	end

	local data = SelectSQLData( ent )
	if not data then return end

	sql.Query( "DELETE FROM star_trek_entities WHERE id = " .. sql.SQLStr( data.id ) )
end

function StarTrekEntities.Data:RemoveSQLData( ent )
	RemoveSQLData( ent )
end

local function SaveSQLData( ent )
	if not IsValid( ent ) then return end
	if not ent:GetModel() or ent:GetModel() == "" then return end

	local pos = ent:GetPos()
	local ang = ent:GetAngles()
	pos = { pos.x, pos.y, pos.z }
	ang = { ang.p, ang.y, ang.r }

	local data = {
		ent_class = ent:GetClass(),
		ent_model = ent:GetModel(),
		ent_pos = util.TableToJSON( { pos = pos, ang = ang } ),
		data = util.TableToJSON( ent:GetSaveTable() )
	}

	sql.Query( "INSERT INTO star_trek_entities (ent_class, ent_model, ent_pos, data) VALUES (" .. sql.SQLStr( data.ent_class ) .. ", " .. sql.SQLStr( data.ent_model ) .. ", " .. sql.SQLStr( data.ent_pos ) .. ", " .. sql.SQLStr( data.data ) .. ")" )
	return sql.QueryValue( "SELECT last_insert_rowid()" )
end
function StarTrekEntities.Data:SaveSQLData( ent )
	return SaveSQLData( ent )
end

local savable_entities = {
	["commsarray"] = true,
	["disablegravity_deck"] = true,
	["disablegravity_section"] = true,
	["disablelifesupport_deck"] = true,
	["disablelifesupport_section"] = true,
	["lifesupport"] = true,
	["gravgen"] = true,
}

local function ReloadStarTrekEntities()
	local result = sql.Query( "SELECT * FROM star_trek_entities" )
	if not result then
		print( "No entities found in the database." )
		return
	end

	for ent_class, _ in pairs( savable_entities ) do
		for _, ent in ipairs( ents.FindByClass( ent_class ) ) do
			if IsValid( ent ) and ent.SQL_ID then
				ent:Remove()
			end
		end
	end

	local ent_count = 0
	for _, row in ipairs( result ) do
		local ent = ents.Create( row.ent_class )
		if not IsValid( ent ) then continue end

		ent:SetModel( row.ent_model )
		local ent_pos = DecodeEntityTransform( row.ent_pos )
		if not ent_pos then
			print( "Failed to decode position for entity: " .. row.ent_class .. " with model: " .. row.ent_model )
			ent:Remove()
			continue
		end
		ent:SetPos( ent_pos.pos )
		ent:SetAngles( ent_pos.ang )
		ent:Spawn()

		local data = util.JSONToTable( row.data or "" )
		if data then
			for k, v in pairs( data ) do
				if ent[k] ~= nil then
					ent[k] = v
				end
			end
		end
		ent:Activate()
		-- ent:Freeze( true )

		ent.SQL_ID = row.id
		ent_count = ent_count + 1
	end
	print( "All entities loaded from the database. " .. ent_count .. " entities loaded." )
end
StarTrekEntities.Data.ReloadStarTrekEntities = ReloadStarTrekEntities

hook.Add( "InitPostEntity", "ReloadStarTrekEntities", function()
	timer.Simple(1, function()
		CreateSQLTable()
		ReloadStarTrekEntities()
	end )
end )

concommand.Add( "star_trek_entities_save", function( ply, cmd, args )
	if not IsValid( ply ) or not ply:IsAdmin() then
		print( "You must be an admin to use this command." )
		return
	end

	local trace = ply:GetEyeTrace()
	if not trace.Entity or not trace.Entity:IsValid() or not savable_entities[trace.Entity:GetClass()] then
		print( "You must be looking at a valid Star Trek entity." )
		return
	end
	CreateSQLTable()

	local ent = trace.Entity
	local existing_data = SelectSQLData( ent )
	if existing_data then
		print( "Entity data already exists, removing old data." )
		RemoveSQLData( ent )
	end

	local last_insert_id = SaveSQLData( ent )
	if not last_insert_id then
		print( "Failed to save entity data." )
		return
	end
	ent.SQL_ID = last_insert_id
	print( "Entity data saved successfully with ID: " .. last_insert_id )
end )

concommand.Add( "star_trek_entities_load", function( ply, cmd, args )
	if not IsValid( ply ) or not ply:IsAdmin() then
		print( "You must be an admin to use this command." )
		return
	end

	CreateSQLTable()
	ReloadStarTrekEntities()
end )

concommand.Add( "star_trek_entities_remove", function( ply, cmd, args )
	if not IsValid( ply ) or not ply:IsAdmin() then
		print( "You must be an admin to use this command." )
		return
	end
	CreateSQLTable()
	local trace = ply:GetEyeTrace()
	if not trace.Entity or not trace.Entity:IsValid() or not savable_entities[trace.Entity:GetClass()] then
		print( "You must be looking at a valid Star Trek entity." )
		return
	end
	local data = SelectSQLData( trace.Entity )
	if not data then
		print( "No data found for the entity." )
		return
	end
	RemoveSQLData( trace.Entity )
	print( "Entity data removed." )
end )

hook.Add( "PostCleanupMap", "StarTrekEntitiesCleanup", function()
	timer.Simple(1, function()
		CreateSQLTable()
		ReloadStarTrekEntities()
	end )
end )
