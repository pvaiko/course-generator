--loadfile( 'courseplay/generateCourse.lua')
require( 'track' )
require( 'Pickle' )

-- parameters 
--
-- how close the vehicle must be to the field to automatically 
-- calculate a track starting near the vehicle's location
-- This is in meters
maxDistanceFromField = 30
--

-- Number of headland tracks to generate
nHeadlandPasses = 6

-- Enable generating parallel tracks which intersect a field boundary
-- more than twice: that is, try to fit the tracks into a concave field
enableSplitTracks = false

-- Distance of waypoints on the generated track in meters
waypointDistance = 5

inputFields = {}
fields = {}

leftMouseKeyPressedAt = {}
leftMouseKeyPressed = false
pointSize = 1
lineWidth = 0.1
scale = 2.0
xOffset, yOffset = 1000, 1000

marks = {}
--
-- read the log.txt to get field polygons. I changed generateCourse.lua
-- so it writes the coordinates to log.txt when a course is generated for a field.

function loadFieldsFromLogFile( fileName, fieldName )
  local i = 1 
  for line in io.lines(fileName )
  do
    match = string.match( line, '%[dbg7 %w+%] generateCourse%(%) called for "Field (%w+)"' )
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
  fields[ fileName ] = fromCpField( fileName, unpickled.boundary )
  io.close( f )
  --local reversed = reverse( unpickled.boundary )
  --local new  = { name=fileName, boundary=reversed }
  --io.output( fileName .. "_reversed.pickle" )
  --io.write( pickle( new ))
  f = io.open( fileName .. "_vehicle.pickle" )
  if f then
    fields[ fileName ].vehicle = unpickle( f:read( "*all" )) 
    io.close( f )
  end
end


-- get the vertices for LOVE of a polygon
function getVertices( polygon )
  local vertices = {}
  for i, point in ipairs( polygon ) do
    table.insert( vertices, point.x )
    table.insert( vertices, -point.y )
  end
  return vertices
end

function drawPoints( polygon )
  love.graphics.setColor( 0, 255, 255 )
  love.graphics.points( getVertices( polygon ))
  for i, point in ipairs( polygon ) do
    if point.tangent then
      love.graphics.print( string.format( "- %d -", i ), point.x, -point.y, -point.tangent.angle + math.pi/2, 0.2 )
    end
  end
end

function drawMarks( points )
  love.graphics.setColor( 200, 200, 0 )
  for i, point in pairs( points ) do
    love.graphics.circle( "line", point.x, -point.y, 1 )
  end
end 

function love.load( arg )
  loadFieldFromPickle(arg[ 2 ])
  --loadFieldsFromLogFile(arg[ 2 ])
  if ( arg[ 3 ] == "showOnly" ) then 
    showOnly = true
  else
    showOnly = false
    for i, field in pairs( fields ) do
      print( " =========== Field " .. i .. " ==================" )
      field.vertices = getVertices( field.boundary )
      field.boundingBox = getBoundingBox( field.boundary )
      calculatePolygonData( field.boundary )
      field.headlandTracks = {}
      local previousTrack = field.boundary
      local implementWidth = 3
      for j = 1, nHeadlandPasses do
        local width
        if j == 1 then 
          width = implementWidth / 2 
        else 
          width = implementWidth
        end
        field.headlandTracks[ j ] = calculateHeadlandTrack( previousTrack, width )
        previousTrack = field.headlandTracks[ j ]
      end
      linkHeadlandTracks( field, implementWidth )
      field.track = generateTracks( field.headlandTracks[ nHeadlandPasses ], implementWidth )
      -- get the bounding box of all fields
      if xOffset > field.boundingBox.minX then xOffset = field.boundingBox.minX end
      if yOffset > field.boundingBox.minY then yOffset = field.boundingBox.minY end
    end
  end
  -- translate everything so they are visible
  xOffset = -xOffset
  yOffset = yOffset
  love.graphics.setPointSize( pointSize )
  love.graphics.setLineWidth( lineWidth )
  love.window.setMode( 1024, 800 )
end

function drawFieldData( field )
  love.graphics.setColor( 200, 200, 0 )
  love.graphics.print( string.format( "Field " .. field.name .. " dir = " 
    .. field.headlandTracks[ nHeadlandPasses ].bestDirection.dir), 
    field.boundingBox.minX, -field.boundingBox.minY,
    0, 2 )
end

function drawVehicle( vehicle )
  -- as always, we invert the y axis for LOVE
  love.graphics.setColor( 200, 0, 200 )
  love.graphics.circle( "line", vehicle.location.x, -vehicle.location.y, 5 )
  -- show vehicle heading
  local d = addPolarVectorToPoint( vehicle.location, math.rad( vehicle.heading ), 20 )
  love.graphics.line( vehicle.location.x, -vehicle.location.y, d.x, -d.y )
end

function drawFields()
  for i, field in pairs( fields ) do
    if field.vertices then
      love.graphics.setColor( 100, 100, 100 )
      love.graphics.polygon('line', field.vertices)
      drawPoints( field.boundary )
      for i, track in ipairs( field.headlandTracks ) do
        love.graphics.setColor( 0, 0, 255 )
        love.graphics.polygon('line', getVertices( track ))
        drawPoints( track )
      end
      if field.headlandPath then
        love.graphics.setColor( 100, 200, 100 )
        love.graphics.line( getVertices( field.headlandPath ))
        --drawPoints( field.headlandPath )
      end
      if field.rotated then
        love.graphics.setColor( 200, 100, 100 )
        love.graphics.line( getVertices( field.rotated ))
      end
      if field.track then
        love.graphics.setColor( 100, 100, 200 )
        love.graphics.line( getVertices( field.track ))
      end
      drawMarks( marks )
      drawFieldData( field )
      if ( field.vehicle ) then 
        drawVehicle( field.vehicle )
      end
      if ( v) then 
        drawVehicle( v)
      end

    end
  end
end

function drawWaypoints()
  for name, course in pairs( fields ) do
    love.graphics.setColor( 0, 255, 255 )
    love.graphics.points( getVertices( course.boundary ))
    for i, point in pairs( course.boundary ) do
      love.graphics.print( string.format( "%d", i ))
    end
  end
end

function love.draw()
  love.graphics.scale( scale, scale )
  love.graphics.translate( xOffset, yOffset )
  love.graphics.setPointSize( pointSize )
  if ( showOnly ) then
    drawWaypoints()
  else
    drawFields()
  end

end


function love.wheelmoved( dx, dy )
  scale = scale + dy * 0.1
  pointSize = pointSize + dy * 0.1
end

function love.mousepressed(x, y, button, istouch)
   if button == 1 then 
      leftMouseKeyPressedAt = { x=x, y=y }
      leftMouseKeyPressed = true
   end
end

function love.mousereleased(x, y, button, istouch)
   if button == 1 then 
      leftMouseKeyPressed = false
   end
end

function love.mousemoved( x, y, dx, dy )
  if leftMouseKeyPressed then
    xOffset = xOffset + dx
    yOffset = yOffset + dy
  end
end
