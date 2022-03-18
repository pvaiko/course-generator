-- all functions dealing with reading/writing files
--
--
--- Reconstruct a field from a Courseplay saved course.
-- As the saved course does not contain the field data we use the 
-- first headland track as the field boundary
--
function loadFieldFromSavedCourse( fileName )
  local f = io.input( fileName )
  local field = {}
  field.name = fileName
  field.boundary = {}
  for line in io.lines( fileName ) do
    local width, nHeadlandPasses, isClockwise = string.match( line, '<course workWidth="([%d%.-]+)" numHeadlandLanes="(%d+)" headlandDirectionCW="(%w+)"' )
    if width then
      field.width = tonumber( width )
      field.nHeadlandPasses = tonumber( nHeadlandPasses )
      field.isClockwise = isClockwise 
    end
    local num, cx, cz, lane = string.match( line, '<waypoint(%d+).+pos="([%d%.-]+) ([%d%.-]+)" +lane="([%d-]+)"')
    -- lane -1 is the outermost headland track
    if lane == "-1" then
      table.insert( field.boundary, { x=tonumber( cx ), y=-tonumber( cz )})
    end
  end
  field.boundary:calculateData()
  return field
end


--- Read the CP saved fields 
function loadSavedFields( fileName )
  local savedFields = {}
  local ix = 0
  for line in io.lines( fileName ) do
    local fieldNum = string.match( line, '<field fieldNum="([%d%.-]+)"' )
    if fieldNum then
      -- a new field started
      ix = tonumber( fieldNum )
      savedFields[ ix ] = { number=fieldNum, boundary={}, islandNodes={}}
    end
    local num, cx, cz = string.match( line, '<point(%d+).+pos="([%d%.-]+) [%d%.-]+ ([%d%.-]+)"' )
    if num then 
      table.insert( savedFields[ ix ].boundary, { x=tonumber( cx ), y=-tonumber( cz )})
	end
	num, cx, cz = string.match( line, '<islandNode(%d+).+pos="([%d%.-]+) +([%d%.-]+)"' )
	if num then
	  table.insert( savedFields[ ix ].islandNodes, { x=tonumber( cx ), y=-tonumber( cz )})
	end
  end
  return savedFields
end

