--loadfile( 'courseplay/generateCourse.lua')
require( 'geo' )
require( 'bspline' )
require( 'Pickle' )
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
      inputFields[ field ].boundary[ i ] = { x=tonumber(x), z=tonumber(z) }
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
      fields[ key ].boundary[ i ] = { x=field.boundary[ i ].x, y=-field.boundary[ i ].z }
    end
  end
end

--- convert a field from the CP representation to a format we are 
-- more comfortable with, for example turn it into x,y from x,-z
function fromCpField( fileName, field )
  result= { boundary = {}, name=fileName }
  for i in ipairs( field ) do
    -- z axis is actually y and is  from north to south 
    -- so need to invert it to get a useful direction
    result.boundary[ i ] = { x=field[ i ].cx, y=-field[ i ].cz }
  end
  return result
end

function loadFieldFromPickle( fileName )
  io.input( fileName )
  fields[ fileName ] = fromCpField( fileName, unpickle( io.read( "*all" )))
end

function getHeadlandTrack( polygon, offset )
  local track = {}
  for i, point in ipairs( polygon ) do
    -- get a point perpendicular to the current point in offset distance
    local newPoint = addPolarVectorToPoint( point.x, point.y, point.tangent.angle + math.pi / 2, offset )
    table.insert( track, { x = newPoint.x, y = newPoint.y })
  end
  calculatePolygonData( track )
  removeLoops( track, 20 )
  removeLoops( track, 20 )
  applyLowPassFilter( track, math.deg( 120 ), 4.1 )
  track = smooth( track, 1 )
  -- don't filter for angle, only distance
  applyLowPassFilter( track, 2 * math.pi, 3 )
  return track
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
  for i, point in pairs( polygon ) do
    if point.tangent then
      --love.graphics.print( string.format( "-- %d: %3d --", i, math.deg( point.tangent )), point.x, -point.y, -point.tangent + math.pi/2, 0.2 )
    end
  end
end

function drawMarks( points )
  love.graphics.setColor( 128, 0, 0 )
  for i, point in pairs( points ) do
    love.graphics.circle( "line", point.x, -point.y, 1 )
  end
end 

function love.load( arg )
  loadFieldFromPickle(arg[ 2 ])
  if ( arg[ 3 ] == "showOnly" ) then 
    showOnly = true
  else
    showOnly = false
    for i, field in pairs( fields ) do
      print( " =========== Field " .. i .. " ==================" )
      field.vertices = getVertices( field.boundary )
      field.boundingBox = getBoundingBox( field.boundary )
      print( field.boundingBox.minX, field.boundingBox.minY )
      print( field.boundingBox.maxX, field.boundingBox.maxY )
      calculatePolygonData( field.boundary )
      field.headlandTracks = {}
      local previousTrack = field.boundary
      local implementWidth = 3
      for j = 1, 6 do
        local width
        if j == 1 then 
          width = implementWidth / 2 
        else 
          width = implementWidth
        end
        field.headlandTracks[ j ] = getHeadlandTrack( previousTrack, width )
        previousTrack = field.headlandTracks[ j ]
      end
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
end

function drawFieldData( field )
  love.graphics.setColor( 200, 200, 0 )
  love.graphics.print( string.format( "Field " .. field.name .. " dir = " 
    .. field.boundary.bestDirection.dir), 
    field.boundingBox.minX, -field.boundingBox.minY,
    0, 2 )
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
      drawMarks( marks )
      drawFieldData( field )
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
