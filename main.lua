require( 'track' )
require( 'file' )
require( 'Pickle' )

field = {}

leftMouseKeyPressedAt = {}
leftMouseKeyPressed = false
pointSize = 1
lineWidth = 0.1
scale = 1.0
xOffset, yOffset = 10000, 10000
windowWidth = 1024
windowHeight = 800
showWidth = false

marks = {}

function love.load( arg )
  if arg[ 2 ] == "fromCourse" then
    -- use the outermost headland path as the basis of the 
    -- generation, that is, the field.boundary is actually
    -- a headland pass of a course
    useHeadland = true
  else
    -- the field boundary is the actual boundary
    useHeadland = false
  end
  fileName = arg[ 3 ]
  field = loadFieldFromSavedCourse( fileName )
  calculatePolygonData( field.boundary )
  field.vehicle = { location = {x=335, y=145}, heading = 180 }
  field.vehicle = { location = {x=-33.6, y=-346.1}, heading = 180 }
  field.boundingBox = getBoundingBox( field.boundary )
  field.vertices = getVertices( field.boundary )
  field.overlap = 0
  field.nTracksToSkip = 0
  field.extendTracks = 0
  field.minDistanceBetweenPoints = 0.5
  field.angleThresholdDeg = 90
  field.doSmooth = false
  
  -- translate and scale everything so they are visible
  fieldWidth = field.boundingBox.maxX - field.boundingBox.minX
  fieldHeight = field.boundingBox.maxY - field.boundingBox.minY
  local xScale = windowWidth / fieldWidth
  local yScale = windowHeight / fieldHeight
  if xScale > yScale then
    scale = 0.9 * yScale
  else
    scale = 0.9 * xScale
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
  love.window.setTitle( "Course Generator" )
end


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
  local buttonPressed = love.window.showMessageBox( "Saving", "Saving " .. fileName .. ", will overwrite if exist.\nDo you want to save?\n", { "Cancel", "Save" })
  print( buttonPressed )
  if buttonPressed == 2 then
    -- Save
    writeCourseToFile( field, fileName )
  end
end

function drawPoints( polygon )
  love.graphics.setColor( 0, 255, 255 )
  love.graphics.points( getVertices( polygon ))
  -- for text, don't flip y axis as it results in mirrored characters
  love.graphics.push()
  love.graphics.scale( 1, -1 )
  for i, point in ipairs( polygon ) do
    if i < 5 or i > #polygon - 5 then
      -- -y as y axis isn't flipped now
      --love.graphics.print( string.format( "%d", i ), point.x, -point.y, 0, 0.2 )
    end
  end
  love.graphics.pop()
end

function drawSettings()
  -- for text, don't flip y axis as it results in mirrored characters
  love.graphics.push()
  love.graphics.translate( -xOffset, -yOffset )
  love.graphics.scale( 1 / scale , -1 / scale )
  love.graphics.setColor( 200, 200, 200 )
  love.graphics.print( string.format( "file: %s", arg[ 3 ]), 10, 10, 0, 1 )
  love.graphics.setColor( 00, 200, 00 )
  love.graphics.print( string.format( "width: %.1f m, overlap %d%% headland passes: %d, skipping %d tracks, extend %d m", 
           field.width, field.overlap, field.nHeadlandPasses, field.nTracksToSkip, field.extendTracks ), 10, 30, 0, 1 )
  love.graphics.print( string.format( "min point distance: %f, angle threshold: %d", field.minDistanceBetweenPoints, field.angleThresholdDeg ), 10, 50, 0, 1 )
  if field.bestAngle then
    love.graphics.setColor( 200, 200, 00 )
    love.graphics.print( string.format( "best angle: %d has %d tracks", field.bestAngle, field.nTracks ), 10, 70, 0, 1 )
  end
  -- help text
  local y = windowHeight - 260
  love.graphics.setColor( 240, 240, 240 )
  love.graphics.print( "Keys:", 10, y, 0, 1 )
  y = y + 20
  love.graphics.setColor( 200, 200, 200 )
  love.graphics.print( "Right click - place vehicle", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "j/k - -/+ vehicle rotation", 10,y, 0, 1 )
  y = y + 20
  love.graphics.print( "h - show headland pass width", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "w/W - -/+ work width", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "x/X - -/+ extend center tracks into headland (m)", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "o/O - -/+ work width overlap on headland", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "p/P - -/+ headland passes", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( ",/< - -/+ min. distance between points", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "./> - -/+ smoothing angle threshold", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "s - toggle corner smoothing", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "r - reverse course", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "a/A - tracks to skip between alternating tracks", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "g - generate course", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "s - save course", 10, y, 0, 1 )
  love.graphics.pop()
end

function drawMarks( points )
  love.graphics.setColor( 200, 200, 0 )
  for i, point in pairs( points ) do
    love.graphics.circle( "line", point.x, point.y, 1 )
  end
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

function drawHeadlandTracks()
  for i, t in ipairs( field.headlandTracks ) do
    love.graphics.setColor( 255, 255, 0 )
    love.graphics.points( getVertices( t ))
    for j, p in ipairs( t ) do
      love.graphics.setColor( 255, 0, 0 )
      love.graphics.line( p.x, p.y, p.x + p.nextEdge.dx / 2, p.y + p.nextEdge.dy / 2 )
    end
  end
end

function drawCoursePoints( course )
  for i, point in ipairs( course ) do
    if point.turnStart then
      love.graphics.setColor( 255, 0, 0 )
    elseif point.turnEnd then
      love.graphics.setColor( 0, 255, 0 )
    else
      love.graphics.setColor( 255, 255, 0 )
    end
    love.graphics.points( point.x, point.y )
  end
end


function drawField( field )
  if field.vertices then
    if ( field.boundingBox ) then
      --drawBoundingBox( field.boundingBox )
    end
    if field.headlandTracks then
      --drawHeadlandTracks()
    end

    -- draw connected headland passes with width
    if field.headlandPath and #field.headlandPath > 0 then
      if showWidth then
        love.graphics.setLineWidth( field.width )
        love.graphics.setColor( 100, 200, 100, 100 )
      else
        love.graphics.setLineWidth( lineWidth )
        love.graphics.setColor( 100, 200, 100 )
      end
      love.graphics.line( getVertices( field.headlandPath ))
    end
    -- draw entire course
    if field.course then
      -- course line
      love.graphics.setColor( 50, 50, 50 )
      love.graphics.setLineWidth( lineWidth )
      love.graphics.line( getVertices( field.course ))
      love.graphics.setLineWidth( lineWidth )
      -- start of course, green dot
      love.graphics.setColor( 0, 255, 0, 80 )
      love.graphics.circle( "fill", field.course[ 1 ].x, field.course[ 1 ].y, 5 )
      love.graphics.setColor( 255, 0, 0, 80 )
      -- end of course, red dot
      love.graphics.circle( "fill", field.course[ #field.course ].x, field.course[ #field.course ].y, 5 )
      love.graphics.setColor( 100, 100, 100 )
      -- course points
      drawCoursePoints( field.course )
    end
    -- draw field boundary
    love.graphics.setColor( 100, 100, 100 )
    love.graphics.polygon('line', field.vertices)
    if ( field.headlandTracks ) then
      if field.headlandTracks[ #field.headlandTracks ].pathFromHeadlandToCenter then
        love.graphics.setColor( 160, 000, 000, 90 )
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
    -- draw tracks in field body
    if field.track then
      love.graphics.setLineWidth( lineWidth )
      love.graphics.setColor( 100, 100, 200 )
      love.graphics.line( getVertices( field.track ))
    end
    drawMarks( marks )
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
      --love.graphics.print( string.format( "%d", i ))
    end
end

function love.draw()
  love.graphics.scale( scale, -scale )
  love.graphics.translate( xOffset, yOffset )
  love.graphics.setPointSize( pointSize )
  if ( showOnly ) then
    drawWaypoints(field.course)
  else
    drawField(field)
  end
  drawSettings()
end

function generate()
  marks = {}
  --status, err = pcall(generateCourseForField, field, field.width, field.nHeadlandPasses, 
  --                                            field.overlap, useHeadland, field.nTracksToSkip,
  --                                            field.extendTracks)
  status, err = generateCourseForField( field, field.width, field.nHeadlandPasses, 
                                              field.overlap, useHeadland, field.nTracksToSkip,
                                              field.extendTracks, field.minDistanceBetweenPoints,
                                              math.rad( field.angleThresholdDeg ), field.doSmooth
                                              )
  if not status then
    print( err )
    --love.window.showMessageBox( "Error", "Could not generate course.", { "Ok" }, "error" )
  end
end

function love.textinput( t )
  if t == "g" then
    generate()
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
  if t == "W" then
    field.width = field.width + 0.1
    generate()
  end
  if t == "w" then
    field.width = field.width - 0.1
    generate()
  end
  if t == "X" then
    field.extendTracks = field.extendTracks + 1
    generate()
  end
  if t == "x" then
    field.extendTracks = field.extendTracks - 1
    generate()
  end
  if t == "o" then
    field.overlap = field.overlap - 5 
    generate()
  end
  if t == "O" then
    field.overlap = field.overlap + 5 
    generate()
  end
  if t == "P" then
    field.nHeadlandPasses = field.nHeadlandPasses + 1
    generate()
  end
  if t == "p" then
    if field.nHeadlandPasses > 2 then
      field.nHeadlandPasses = field.nHeadlandPasses - 1
      generate()
    end
  end
  if t == "h" then
    showWidth = not showWidth
  end
  if t == "r" then
    field.course = reverseCourse( field.course )
  end
  if t == "A" then
    if field.nTracksToSkip < 5 then
      field.nTracksToSkip = field.nTracksToSkip + 1
      generate()
    end
  end
  if t == "a" then
    if field.nTracksToSkip > 0 then
      field.nTracksToSkip = field.nTracksToSkip - 1
      generate()
    end
  end
  if t == "," then
    if field.minDistanceBetweenPoints > 0.25 then
      field.minDistanceBetweenPoints = field.minDistanceBetweenPoints - 0.25
      generate()
    end
  end
  if t == "<" then
    field.minDistanceBetweenPoints = field.minDistanceBetweenPoints + 0.25
    generate()
  end
  if t == "." then
    if field.angleThresholdDeg > 30 then
      field.angleThresholdDeg = field.angleThresholdDeg - 15
      generate()
    end
  end
  if t == ">" then
    field.angleThresholdDeg = field.angleThresholdDeg + 15
    generate()
  end
  if t == "m" then
    field.doSmooth = not field.doSmooth
    generate()
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
