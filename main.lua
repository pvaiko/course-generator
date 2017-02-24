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
field = {}

leftMouseKeyPressedAt = {}
leftMouseKeyPressed = false
pointSize = 1
lineWidth = 0.1
scale = 1.0
xOffset, yOffset = 10000, 10000
windowWidth = 1024
windowHeight = 800

marks = {}

-- get the vertices for LOVE of a polygon
function getVertices( polygon )
  local vertices = {}
  for i, point in ipairs( polygon ) do
    table.insert( vertices, point.x )
    table.insert( vertices, point.y )
  end
  return vertices
end

function love2real( x, y )
  return ( x / scale ) - xOffset,  - ( y / scale ) - yOffset
end

function saveFile()
  love.window.showMessageBox( "Save", "Saving", { "Cancel", "Save" })
end

function drawPoints( polygon )
  love.graphics.setColor( 0, 255, 255 )
  love.graphics.points( getVertices( polygon ))
  for i, point in ipairs( polygon ) do
    if i < 5 or i > #polygon - 5 then
      love.graphics.print( string.format( "%d", i ), point.x, point.y, 0, 0.2 )
    end
  end
end

function drawMarks( points )
  love.graphics.setColor( 200, 200, 0 )
  for i, point in pairs( points ) do
    love.graphics.circle( "line", point.x, point.y, 1 )
  end
end 

function love.load( arg )
  field = loadFieldFromSavedCourse( arg[ 2 ])
  calculatePolygonData( field.boundary )
  field.vehicle = { location = {x=335, y=145}, heading = 180 }
  field.nHeadlandPasses = 5
  field.width = 4.4
  field.boundingBox = getBoundingBox( field.boundary )
  field.vertices = getVertices( field.boundary )
  
  -- translate and scale everything so they are visible
  fieldWidth = field.boundingBox.maxX - field.boundingBox.minX
  fieldHeight = field.boundingBox.maxY - field.boundingBox.minY
  if fieldWidth > fieldHeight then
    -- scale according to the width
    scale = 0.9 * windowWidth / fieldWidth
  else
    scale = 0.9 * windowHeight / fieldHeight
  end

  fieldCenterX = ( field.boundingBox.maxX + field.boundingBox.minX ) / 2
  fieldCenterY = ( field.boundingBox.maxY + field.boundingBox.minY ) / 2
  -- translate into the middle of the window and remember, the window size is not scaled so must
  -- divide by scale
  xOffset = - (  fieldCenterX - windowWidth / 2 / scale )
  -- need to offset with window height as we flip the y axle so the origo is in the bottom left corner
  -- of the window
  yOffset = - (  fieldCenterY - windowHeight / 2 / scale ) - windowHeight / scale
  love.graphics.setPointSize( pointSize )
  love.graphics.setLineWidth( lineWidth )
  love.window.setMode( windowWidth, windowHeight )
end

function drawFieldData( field )
  love.graphics.setColor( 200, 200, 0 )
  love.graphics.print( string.format( "Field " .. field.name .. " dir = " 
    .. field.headlandTracks[ #field.headlandTracks ].bestDirection.dir), 
    field.boundingBox.minX, -field.boundingBox.minY,
    0, 2 )
end

function drawVehicle( vehicle )
  -- as always, we invert the y axis for LOVE
  love.graphics.setColor( 200, 0, 200 )
  love.graphics.circle( "line", vehicle.location.x, vehicle.location.y, 5 )
  -- show vehicle heading
  local d = addPolarVectorToPoint( vehicle.location, math.rad( vehicle.heading ), 20 )
  love.graphics.line( vehicle.location.x, vehicle.location.y, d.x, d.y )
end

function drawBoundingBox( bb )
  love.graphics.line( bb.minX, bb.minY, bb.maxX, bb.minY, bb.maxX, bb.maxY, bb.minX, bb.maxY, bb.minX, bb.minY )
end

function drawField( field )
  if field.vertices then
    if ( field.boundingBox ) then
      --drawBoundingBox( field.boundingBox )
    end
    if field.course then
      love.graphics.setColor( 50, 50, 50 )
      love.graphics.setLineWidth( lineWidth * 10 )
      love.graphics.line( getVertices( field.course ))
      love.graphics.setLineWidth( lineWidth )
      love.graphics.setColor( 100, 100, 100 )
      drawPoints( field.course )
    end
    love.graphics.setColor( 100, 100, 100 )
    love.graphics.polygon('line', field.vertices)
    --drawPoints( field.boundary )
    if ( field.headlandTracks ) then
      for i, track in ipairs( field.headlandTracks ) do
        love.graphics.setColor( 0, 0, 255 )
        --love.graphics.polygon('line', getVertices( track ))
        drawPoints( track )
      end
      if field.headlandTracks[ #field.headlandTracks ].pathFromHeadlandToCenter then
        love.graphics.setColor( 160, 000, 000 )
        local points = field.headlandTracks[ #field.headlandTracks ].pathFromHeadlandToCenter
        if #points > 1 then
          love.graphics.setLineWidth( lineWidth * 20 )
          love.graphics.line( getVertices( points ))
          love.graphics.setLineWidth( lineWidth )
        else
          love.graphics.circle( "line", points[ 1 ].x, points[ 1 ].y, 1 )
        end
      end
    end
    if field.headlandPath then
      love.graphics.setColor( 100, 200, 100 )
      love.graphics.line( getVertices( field.headlandPath ))
      --drawPoints( field.headlandPath )
    end
    if field.track then
      love.graphics.setColor( 100, 100, 200 )
      love.graphics.line( getVertices( field.track ))
      --drawPoints( field.track )
    end
    drawMarks( marks )
    --drawFieldData( field )
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

function drawWaypoints( course )
    love.graphics.setColor( 0, 255, 255 )
    love.graphics.points( getVertices( course.boundary ))
    for i, point in pairs( course.boundary ) do
      love.graphics.print( string.format( "%d", i ))
    end
end

function love.draw()
  --love.graphics.translate( scale * xOffset, scale * yOffset )
  love.graphics.scale( scale, -scale )
  love.graphics.translate( xOffset, yOffset )
  love.graphics.setPointSize( pointSize )
  if ( showOnly ) then
    drawWaypoints(field.course)
  else
    drawField(field)
  end
end

function love.textinput( t )
  if t == "g" then
    marks = {}
    generateCourseForField( field, field.width, field.nHeadlandPasses, false )
  end
  if t == "j" then
    field.vehicle.heading = field.vehicle.heading + 5
  end
  if t == "k" then
    field.vehicle.heading = field.vehicle.heading - 5
  end
  if t == "s" then
    saveFile()
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
   if button == 2 then
     cix, ciy = love2real( x, y )
     print( cix, ciy )
     field.vehicle.location.x = cix
     field.vehicle.location.y = ciy
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
    yOffset = yOffset - dy
  end
end
