--loadfile( 'courseplay/generateCourse.lua')
require( 'geo' )
require( 'bspline' )
fields = {}

leftMouseKeyPressedAt = {}
leftMouseKeyPressed = false
pointSize = 1
lineWidth = 1
scale = 2.0
xOffset, yOffset = 1000, 1000

marks = {}
--
-- read the log.txt to get field polygons. I changed generateCourse.lua
-- so it writes the coordinates to log.txt when a course is generated for a field.

function loadFields( fileName, fieldName )
  local i = 1 
  for line in io.lines(fileName )
  do
    match = string.match( line, '%[dbg7 %w+%] generateCourse%(%) called for "Field (%w+)"' )
    if match then 
      -- start of a new field data 
      field = match
      print("Reading field " .. field ) 
      i = 1
      fields[ field ] = { boundary = {}, name=field }
    end
    x, y, z = string.match( line, "%[dbg7 %w+%] ([%d%.-]+) ([%d%.-]+) ([%d%.-]+)" )
    if x then 
      -- z axis is actually y and is  from north to south 
      -- so need to invert it to get a useful direction
      fields[ field ].boundary[ i ] = { x=tonumber(x)*2, y=-tonumber(z)*2  }
      i = i + 1
    end
  end
  --fields[ "rect" ] = { boundary = createRectangularPolynom( 40, 300, 200, 100, 4 ), name = "rect" }
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
  track = smooth( track, 2 )
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
  loadFields(arg[ 2 ])
  for i, field in pairs( fields ) do
    print( " =========== Field " .. i .. " ==================" )
    field.vertices = getVertices( field.boundary )
    field.boundingBox = getBoundingBox( field.boundary )
    print( field.boundingBox.minX, field.boundingBox.minY )
    print( field.boundingBox.maxX, field.boundingBox.maxY )
    calculatePolygonData( field.boundary )
    field.headlandTracks = {}
    local previousTrack = field.boundary
    for j = 1, 6 do
      field.headlandTracks[ j ] = getHeadlandTrack( previousTrack, 4.3 )
      previousTrack = field.headlandTracks[ j ]
    end
    -- get the bounding box of all fields
    if xOffset > field.boundingBox.minX then xOffset = field.boundingBox.minX end
    if yOffset > field.boundingBox.minY then yOffset = field.boundingBox.minY end
  end
  -- translate everything so they are visible
  xOffset = -xOffset
  yOffset = -yOffset
  love.graphics.setPointSize( pointSize )
  love.graphics.setLineWidth( lineWidth )
end

function drawFieldData( field )
   
  love.graphics.setColor( 200, 200, 0 )
  love.graphics.print( string.format( "Field " .. field.name .. " dir = " 
    .. field.boundary.bestDirection.dir), 
    field.boundingBox.minX, field.boundingBox.minY,
    0, 2 )
end

function love.draw()
  love.graphics.scale( scale, scale )
  love.graphics.translate( xOffset, yOffset )
  love.graphics.setPointSize( pointSize )
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
