--loadfile( 'courseplay/generateCourse.lua')
require( 'track' )
require( 'file' )
require( 'Pickle' )

-- parameters 
--
--

-- Number of headland tracks to generate
nHeadlandPasses = 6

inputFields = {}
fields = {}

leftMouseKeyPressedAt = {}
leftMouseKeyPressed = false
pointSize = 1
lineWidth = 0.1
scale = 2.0
xOffset, yOffset = 1000, 1000

marks = {}

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
    if i < 5 or i > #polygon - 5 then
      love.graphics.print( string.format( "%d", i ), point.x, -point.y, 0, 0.2 )
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
  fields[ arg[ 2 ]] = loadFieldFromPickle(arg[ 2 ])
  --loadFieldsFromLogFile(arg[ 2 ])
  if ( arg[ 3 ] == "showOnly" ) then 
    showOnly = true
  else
    showOnly = false
    for i, field in pairs( fields ) do
      print( " =========== Field " .. i .. " ==================" )
      generateCourseForField( field, 5, nHeadlandPasses )
      field.vertices = getVertices( field.boundary )
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
      --drawPoints( field.boundary )
      for i, track in ipairs( field.headlandTracks ) do
        --love.graphics.setColor( 0, 0, 255 )
        --love.graphics.polygon('line', getVertices( track ))
        --drawPoints( track )
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
        drawPoints( field.track )
      end
      if field.headlandTracks[ nHeadlandPasses ].pathFromHeadlandToCenter then
        love.graphics.setColor( 255, 000, 000 )
        love.graphics.line( getVertices( field.headlandTracks[ nHeadlandPasses ].pathFromHeadlandToCenter ))
      end
      drawMarks( marks )
      drawFieldData( field )
      if ( field.vehicle ) then 
        drawVehicle( field.vehicle )
      end
      if vectors then
        for i, vec in ipairs( vectors ) do
          love.graphics.circle( "line", vec[ 1 ].x, -vec[ 1 ].y , 3 )
          love.graphics.line( getVertices( vec ))
        end
      end
      if ( v ) then 
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
