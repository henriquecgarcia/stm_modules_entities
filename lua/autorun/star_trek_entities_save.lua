if not SERVER then return end

local function CreateSQLTable()
	if sql.TableExists( "star_trek_entities" ) then return end

	sql.Query( [[
		CREATE TABLE star_trek_entities (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			ent_class INTEGER NOT NULL,
			ent_model TEXT NOT NULL,
			ent_pos TEXT NOT NULL,
			data TEXT
		)
	]] )
end

local function SelectSQLData( ent )
	if not IsValid( ent ) then return end

	local result = sql.QueryRow( "SELECT * FROM star_trek_entities WHERE ent_class = " .. sql.SQLStr( ent:GetClass() ) .. " AND ent_model = " .. sql.SQLStr( ent:GetModel() or ent:GetModel() ) )
	if not result then return end
	result.data = util.JSONToTable( result.data )
	if not result.data then
		print( "Failed to decode data for entity: " .. ent:GetClass() .. " with model: " .. ent:GetModel() )
		return nil
	end
	result.ent_pos = util.JSONToTable( result.ent_pos )
	if not result.ent_pos or #result.ent_pos ~= 2 then
		print( "Failed to decode position for entity: " .. ent:GetClass() .. " with model: " .. ent:GetModel() )
		return nil
	end
	result.ent_pos = {
		pos = Vector( result.ent_pos[1][1], result.ent_pos[1][2], result.ent_pos[1][3] ),
		ang = Angle( result.ent_pos[2][1], result.ent_pos[2][2], result.ent_pos[2][3] )
	}
	PrintTable(result)
	return result
end

local function RemoveSQLData( ent )
	local data = SelectSQLData( ent )
	if not data then return end

	sql.Query( "DELETE FROM star_trek_entities WHERE id = " .. sql.SQLStr( data.id ) )
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

	print( "Saving entity data for: " .. ent:GetClass() .. " with model: " .. ent:GetModel() )
	PrintTable(data)
	sql.Query( "INSERT INTO star_trek_entities (ent_class, ent_model, ent_pos, data) VALUES (" .. sql.SQLStr( data.ent_class ) .. ", " .. sql.SQLStr( data.ent_model ) .. ", " .. sql.SQLStr( data.ent_pos ) .. ", " .. sql.SQLStr( data.data ) .. ")" )
end

local savable_entities = {
	["commsarray"] = true,
	["disablelifesupport"] = true,
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
		local ent_pos = util.JSONToTable( row.ent_pos )
		if not ent_pos or table.Count(ent_pos) ~= 2 then
			print( "Failed to decode position for entity: " .. row.ent_class .. " with model: " .. row.ent_model )
			ent:Remove()
			continue
		end
		if not ent_pos.pos or not ent_pos.ang then
			print( "Invalid position data for entity: " .. row.ent_class .. " with model: " .. row.ent_model )
			ent:Remove()
			continue
		end
		ent_pos.pos = Vector( ent_pos.pos[1], ent_pos.pos[2], ent_pos.pos[3] )
		ent_pos.ang = Angle( ent_pos.ang[1], ent_pos.ang[2], ent_pos.ang[3] )
		ent:SetPos( ent_pos.pos )
		ent:SetAngles( ent_pos.ang )
		ent:Spawn()

		local data = util.JSONToTable( row.data )
		if data then
			for k, v in pairs( data ) do
				if ent[k] ~= nil then
					ent[k] = v
				end
			end
		end
		ent:Activate()
		ent:Freeze( true )

		ent.SQL_ID = row.id
		ent_count = ent_count + 1
	end
	print( "All entities loaded from the database. " .. ent_count .. " entities loaded." )
end
hook.Add( "InitPostEntity", "ReloadStarTrekEntities", function()
	CreateSQLTable()
	ReloadStarTrekEntities()
end )

hook.Add( "ShouldIgnoreLifeSupportDamagePlayer", "DisableLifeSupportDamage", function( ent, ply, section, deck )
	if not IsValid( ent ) or not ent:IsPlayer() then return end
	local pMovement = ent:GetMoveType()
	if pMovement == MOVETYPE_NOCLIP or pMovement == MOVETYPE_OBSERVER then return true end
	if ply:GetModel() == "models/player/startrek_female_spacesuit.mdl" then return true end
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

	SaveSQLData( ent )
	local last_insert_id = sql.QueryValue( "SELECT last_insert_rowid()" )
	if not last_insert_id then
		print( "Failed to save entity data." )
		return
	end
	local data_saved = sql.Query( "SELECT * FROM star_trek_entities WHERE id = " .. sql.SQLStr( last_insert_id ) )
	if not data_saved then
		print( "Failed to retrieve saved entity data." )
		return
	end
	data_saved = data_saved[1] -- Get the first row of the result.
	data_saved.pos = util.JSONToTable( data_saved.ent_pos )
	if not data_saved.pos or table.Count(data_saved.pos) ~= 2 then
		print( "Failed to decode position for saved entity data." )
		return
	end
	data_saved.pos = {
		pos = Vector( data_saved.pos['pos'][1], data_saved.pos['pos'][2], data_saved.pos['pos'][3] ),
		ang = Angle( data_saved.pos['ang'][1], data_saved.pos['ang'][2], data_saved.pos['ang'][3] )
	}
	data_saved.data = util.JSONToTable( data_saved.data )
	if not data_saved.data then
		print( "Failed to decode data for saved entity." )
		return
	end
	ent:Remove() -- Remove the original entity after saving its data.
	print( "Entity data saved successfully with ID: " .. last_insert_id )

	local new_ent = ents.Create( ent:GetClass() )
	if not IsValid( new_ent ) then
		print( "Failed to create new entity for data." )
		return
	end

	new_ent:SetModel( data_saved.ent_model )
	new_ent:SetPos( data_saved.pos.pos )
	new_ent:SetAngles( data_saved.pos.ang )
	new_ent:Spawn()
	for k, v in pairs( data_saved.data ) do
		if new_ent[k] then
			new_ent[k] = v
		end
	end
	new_ent.SQL_ID = last_insert_id
	new_ent:Activate()

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