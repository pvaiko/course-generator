-- all functions dealing with reading/writing files
--
inputFields = {}

--- convert a field from the CP representation to a format we are 
-- more comfortable with, for example turn it into x,y from x,-z
function fromCpField( fileName, field )
  result = { boundary = {}, name=fileName }
  for i in ipairs( field ) do
    -- z axis is actually y and is  from north to south 
    -- so need to invert it to get a useful direction
    result.boundary[ i ] = { x=field[ i ].cx, y=-field[ i ].cz }
  end
  return result
end

function loadFieldFromPickle( fileName )
  local f = io.input( fileName .. ".pickle" )
  local unpickled = unpickle( io.read( "*all" ))
  local field = fromCpField( fileName, unpickled.boundary )
  io.close( f )
  --local reversed = reverse( unpickled.boundary )
  --local new  = { name=fileName, boundary=reversed }
  --io.output( fileName .. "_reversed.pickle" )
  --io.write( pickle( new ))
  f = io.open( fileName .. "_vehicle.pickle" )
  if f then
    field.vehicle = unpickle( f:read( "*all" )) 
    io.close( f )
  end
  return field
end

--
-- read the log.txt to get field polygons. I changed generateCourse.lua
-- so it writes the coordinates to log.txt when a course is generated for a field.
--
function loadFieldsFromLogFile( fileName, fieldName )
  local i = 1 
  for line in io.lines(fileName ) do
    local match = string.match( line, '%[dbg7 %w+%] generateCourse%(%) called for "Field (%w+)"' )
    if match then 
      -- start of a new field data 
      field = match
      print("Reading field " .. field ) 
      i = 1
      inputFields[ field ] = { boundary = {}, name=field }
    end
    x, y, z = string.match( line, "%[dbg7 %w+%] ([%d%.-]+) ([%d%.-]+) ([%d%.-]+)" )
    if x then 
      inputFields[ field ].boundary[ i ] = { cx=tonumber(x), cz=tonumber(z) }
      i = i + 1
    end
  end
  for key, field in pairs( inputFields ) do
    io.output( field.name .. ".pickle" )
    io.write( pickle( field )) 
    fields[ key ] = { boundary = {}, name=field.name }
    for i in ipairs( field.boundary ) do
      -- z axis is actually y and is  from north to south 
      -- so need to invert it to get a useful direction
      fields[ key ].boundary[ i ] = { x=field.boundary[ i ].cx, y=-field.boundary[ i ].cz }
    end
  end
end

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
  calculatePolygonData( field.boundary )
  return field
end


--- Convert our angle representation (measured from the x axis up in radians)
-- into CP's, where 0 is to the south, to our negative y axis.
--
function toCpAngle( angle )
  local a = math.deg( angle ) + 90
  if a > 180 then
    a = a - 360
  end
  return a
end


--- Write field.course to a CP saved course file
--
function writeCourseToFile( field, fileName )
  local f = io.output( fileName )
  io.write( 
    string.format( '<course workWidth="%.6f" numHeadlandLanes="%d" headlandDirectionCW="%s">\n', 
      field.width, field.nHeadlandPasses, field.isClockwise ))
  local wp = 1
  for i, point in ipairs( field.course ) do
    local lane = ""
    if point.passNumber then
      lane = string.format( 'lane="%d"', -point.passNumber)
    end
    local turn = ""
    if point.turnStart then
      turn = 'turnstart="1"'
    end
    if point.turnEnd then
      turn = 'turnend="1"'
    end
    local crossing = ""
    if i == 1 then 
      crossing = 'crossing="1" wait="1"'
    end
    if i == #field.course then
      crossing = 'crossing="1" wait="1"'
    end
    io.write( 
      string.format( '  <waypoint%d angle="%.2f" origangle="%.2f" generated="true" speed="0" pos="%.2f %.2f" %s %s %s/>\n',
                     wp, toCpAngle( point.toEdge.angle ), math.deg( point.toEdge.angle ), point.x, -point.y, turn, lane, crossing ))
    wp = wp + 1
  end
  io.write( " </course>" )
  io.close( f )
end
--- Read the CP course manager files to find out which courses are 
-- saved in that directory
function getSavedCourses( f )
  local savedCourses = {}
  local maxId = -1
  local maxSequence = -1
  for line in f:lines() do
    local fileName = string.match( line, 'fileName="(%g+)"' )
    local id = string.match( line, 'id="(%d+)"' )
    local name = string.match( line, 'name="(.+)"' )
    local sequence = string.match( line, 'courseStorage(%d+).xml' )
    if id then
      id = tonumber( id )
      sequence = tonumber( sequence )
      savedCourses[ id ] = { fileName=fileName, id=id, name=name, sequence=sequence }
      if ( id > maxId ) then maxId = id end
      if ( id > maxSequence ) then maxSequence = sequence end
    end
  end
  return savedCourses, maxId + 1, maxSequence + 1
end

--- Copy oldCourse to newCourse in dir, and also update the manager file
function copyCourse( dir, oldCourse, newCourse, managerFileName )
  -- first copy the course file
  print( string.format( "Copying %s to %s", oldCourse.fileName, newCourse.fileName ))
  local from = io.open( dir .. "/" .. oldCourse.fileName, "r" )
  local to = io.open( dir .. "/" .. newCourse.fileName, "w" )
  for line in from:lines() do
    to:write( line .. "\n" )
  end
  from:close()
  to:close()

  -- now update the manager file
  local managerFileContents = ""
  local man = io.open( dir .. "/" .. managerFileName, "r" )
  for line in man:lines() do
    managerFileContents = managerFileContents .. line .. "\n"
    local fileName, id, name = string.match( line, 'fileName="(%g+)" +id="(%d+)".+name="(.+)"' )
    -- append new course data after the original courses
    if tonumber( id ) == ( newCourse.id - 1 ) then
      managerFileContents = managerFileContents .. string.format(
        '        <slot fileName="%s" id="%d" parent="0" isUsed="true" name="%s"/>\n',
        newCourse.fileName, newCourse.id, newCourse.name )
    end
  end
  man:close() 

  local man = io.open( dir .. "/" .. managerFileName, "w" )
  man:write( managerFileContents )
  man:close()
end
