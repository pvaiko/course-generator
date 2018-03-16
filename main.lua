dofile( 'include.lua' )

local field = {}
marks = {}
local lines = {}
local helperPolygon = {}
local headlandSettings = {}
local leftMouseKeyPressedAt = {}
local leftMouseKeyPressed = false
local pointSize = 1
local lineWidth = 0.1
local scale = 1.0
local xOffset, yOffset = 10000, 10000
local windowWidth = 1400
local windowHeight = 950
local showWidth = false
local currentWaypointIndex = 1
 
local drawConnectingTracks = true
local drawCourse = true
local showHeadlandPath = true 
local drawTrack = false
local drawBlocks = true
local drawGrid = false
local drawHelpers = true
local showSettings = true
local islandBypassMode = Island.BYPASS_MODE_CIRCLE
headlandSettings.mode = courseGenerator.HEADLAND_MODE_NORMAL
headlandSettings.headlandFirst = true
headlandSettings.nPasses = 1
local centerSettings = { useBestAngle = true, rowAngle = 0 }

-- pathfinding
local path = {}
local reversePath = {}
local gridSpacing = 4.07
local islandNodes = {}

function love.load( arg )
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  fileName = arg[ 3 ]
  if arg[ 2 ] == "fromCourse" then
    field = loadFieldFromSavedCourse( fileName )
  else
    savedFields = loadSavedFields( fileName ) 
    print( "Fields found in file:" )
    for i, f in pairs( savedFields ) do
      print(f.number )
      if f.number == arg[ 4 ] then
        field = f
      end
    end
    field.width = 4
  end 
  islandNodes = field.islandNodes
  field.loadedBoundaryVertices = getVertices( field.boundary )
  headlandSettings.startLocation = {x=field.boundary[ 1 ].x, y=field.boundary[ 1 ].y}

  headlandSettings.overlapPercent = 0
  field.nTracksToSkip = 0
  field.extendTracks = 0
  field.minDistanceBetweenPoints = 0.5
  minSmoothingAngleDeg = 30
  headlandSettings.minHeadlandTurnAngleDeg = 85
  field.doSmooth = true
  headlandSettings.isClockwise = false
  field.roundCorners = true
  field.turningRadius = 13.0
  if arg[ 2 ] == "fromCourse" then
    -- use the outermost headland path as the basis of the 
    -- generation, that is, the field.boundary is actually
    -- a headland pass of a course
    -- calculate the boundary from the headland track
    field.boundary = calculateHeadlandTrack( field.boundary, courseGenerator.HEADLAND_MODE_NORMAL, field.width / 2,
                                             field.minDistanceBetweenPoints, math.rad( minSmoothingAngleDeg), 0, 
                                             field.doSmooth, false, field.turningRadius, nil, nil )
  end
  field.boundary = Polygon:new( field.boundary )
  field.boundingBox = field.boundary:getBoundingBox()
  field.calculatedBoundaryVertices = getVertices( field.boundary )
  -- translate and scale everything so they are visible
  fieldWidth = field.boundingBox.maxX - field.boundingBox.minX
  fieldHeight = field.boundingBox.maxY - field.boundingBox.minY
  local xScale = windowWidth / fieldWidth
  local yScale = windowHeight / fieldHeight
  if xScale > yScale then
    scale = 0.9 * yScale
    pointSize = 0.9 * yScale
  else
    scale = 0.9 * xScale
    pointSize = 0.9 * xScale
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
	generate()
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
  if buttonPressed == 2 then
    -- Save
    writeCourseToFile( field, fileName )
  end
end

function drawPathFindingHelpers()
  -- for text, don't flip y axis as it results in mirrored characters
  love.graphics.push()
  love.graphics.setLineWidth( 1 )
  love.graphics.setColor( 140, 140, 0 )
  if path.course and #path.course > 2 then
    love.graphics.line( getVertices( path.course ))
    love.graphics.setColor( 200, 200, 0 )
    love.graphics.points( getVertices( path.course ))
  end
  if reversePath.course and #reversePath.course > 2 then
    love.graphics.line( getVertices( reversePath.course ))
    love.graphics.setColor( 220, 100, 0 )
    love.graphics.points( getVertices( reversePath.course ))
  end
  if grid and drawGrid then 
    love.graphics.setLineWidth( lineWidth )
    for i, point in ipairs( grid ) do
      local len = 0.3
      if point.hasFruit then
        love.graphics.setColor( 100, 000, 0 )
      else
        love.graphics.setColor( 000, 150, 0 )
      end
      if point.visited then len = 1 end
      love.graphics.line( point.x - len, point.y, point.x + len, point.y )
      love.graphics.line( point.x, point.y - len, point.x, point.y + len )
    end
  end
  love.graphics.pop()
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
  local headlandDirection, roundCorners
  if headlandSettings.isClockwise then
    headlandDirection = "clockwise"
  else
    headlandDirection = "counterclockwise"
  end

  if field.roundCorners then
    roundCorners = "round"
  else
    roundCorners = "sharp"
  end
  love.graphics.print( string.format( "HEADLAND width: %.1f m, overlap %d%% number of passes: %d, direction %s, corners: %s, radius: %.1f",
           field.width, headlandSettings.overlapPercent, headlandSettings.nPasses, headlandDirection, roundCorners, field.turningRadius ), 10, 30, 0, 1 )
  love.graphics.print( string.format( "CENTER skipping %d tracks, extend %d m", 
           field.nTracksToSkip, field.extendTracks ), 10, 50, 0, 1 )
           
  local smoothingStatus 
  if field.doSmooth then smoothingStatus = "on" else smoothingStatus = "off" end
  
  love.graphics.print( string.format( "min point distance: %.2f m, corner smoothing: %s, min. smoothing angle: %d, min. headland turn angle = %d", 
    field.minDistanceBetweenPoints, smoothingStatus, minSmoothingAngleDeg, headlandSettings.minHeadlandTurnAngleDeg ), 10, 70, 0, 1 )
  if field.bestAngle then
	  local angle
	  if centerSettings.useBestAngle then
		  angle = string.format( '%d (best)', field.bestAngle )
	  elseif centerSettings.useLongestEdgeAngle then
		  angle = string.format( '%d (longest edge)', field.bestAngle )
	  else
		  angle = string.format( '%d (%s)', field.bestAngle, courseGenerator.getCompassAngleDeg( field.bestAngle ))
	  end
    love.graphics.setColor( 200, 200, 00 )
    love.graphics.print( string.format( "Options: angle: %s has %d tracks", angle, field.nTracks ), 10, 90, 0, 1 )
  end
  -- Info on waypoint under mouse cursor
  if field.course then
    love.graphics.setColor( 255, 255, 255 )
    --print( currentWaypointIndex )
    local cWp = field.course[ currentWaypointIndex ]
    if cWp then
	    local rev = cWp.rev and 'rev' or 'fwd'
	    local turn = cWp.turnStart and 'start' or ( cWp.turnEnd and 'end' or '')
      love.graphics.print(string.format("ix=%d x=%.1f y=%.1f %.0f°>%.0f° %s %s", currentWaypointIndex, cWp.x, cWp.y, 
        math.deg( cWp.prevEdge.angle ), math.deg( cWp.nextEdge.angle ), turn, rev ),
        windowWidth - 300, windowHeight - 40, 0, 1)
      local radius = 'n/a'
      if cWp.radius then
        if cWp.radius > 100 then
          radius = 'inf'
        else
          radius = string.format( '%.0f', cWp.radius ) 
        end
      end
      local pass = cWp.passNumber or 'n/a'
      local track = cWp.trackNumber or 'n/a' 
	    local origTrack = cWp.originalTrackNumber or 'n/a'
	    local ridgeMarker = cWp.ridgeMarker or 'n/a'
	    local adjacentToIsland = cWp.adjacentIslands and #cWp.adjacentIslands or 'no'
        love.graphics.print(string.format("pass=%s track =%s(%s) r=%s adj=%s rm=%s", tostring( pass), tostring( track ), tostring( origTrack ), radius, adjacentToIsland, tostring( ridgeMarker ) ),
          windowWidth - 300, windowHeight - 20, 0, 1)

      end
  end
  -- help text
  local y = windowHeight - 360
  love.graphics.setColor( 240, 240, 240 )
  love.graphics.print( "KEYS", 10, y, 0, 1 )
  y = y + 20
  love.graphics.setColor( 200, 200, 200 )
  love.graphics.print( "Right click - mark start location", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "c - toggle headland direction (cw/ccw)", 10,y, 0, 1 )
  y = y + 20
  love.graphics.print( "d - toggle round headland corners", 10,y, 0, 1 )
  y = y + 20
  love.graphics.print( "h - toggle headland mode", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "w/W - -/+ work width", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "t/T - -/+ turning radius", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "x/X - -/+ extend center tracks into headland (m)", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "o/O - -/+ work width overlap on headland", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "p/P - -/+ headland passes", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( ",/< - -/+ min. distance between points", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "./> - -/+ min. smoothing angle", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "k/K - -/+ min headland turn angle", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "m - toggle corner smoothing", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "r - reverse course", 10, y, 0, 1 )
  y = y + 20
	love.graphics.print( "q - toggle up/down row angle mode", 10, y, 0, 1 )
	y = y + 20
  love.graphics.print( "a/A - change up/down row angle", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "i - toggle island bypass mode", 10, y, 0, 1 )
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
    if point.label then
      love.graphics.push()
      love.graphics.scale( 1, -1 )
      love.graphics.print( point.label, point.x, -point.y, 0, 0.3 )
      love.graphics.pop()
    end
  end
end 

function drawLines( lines )
  love.graphics.setColor( 200, 100, 0, 200 )
  for i, line in pairs( lines ) do
    love.graphics.line( getVertices( line ))
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

function drawFieldBlocks( blocks )
	if blocks then
		love.graphics.push()	
		local colorStep = 256 / #blocks
		local red, green = 0, 255
		for i, b in ipairs( blocks ) do
			love.graphics.setColor( red, green, 0, 40 )
			love.graphics.polygon( 'fill', getVertices( b.polygon ))
			local bb = b.polygon:getBoundingBox()
			love.graphics.push()
			love.graphics.scale( 1, -1 )
			love.graphics.setColor( red, green, 0, 170 )
			love.graphics.print( i, ( bb.minX + bb.maxX ) / 2, - ( bb.minY + bb.maxY ) / 2 )
			love.graphics.pop()
			red = red + colorStep
			green = green - colorStep
		end
		love.graphics.pop()
	end
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

function drawPolygon( polygon )
  for i, point in ipairs( polygon ) do
    love.graphics.points( point.x, point.y )
    love.graphics.push()
    love.graphics.scale( 1, -1 )
    love.graphics.print( i, point.x, -point.y, 0, 0.2 )
    love.graphics.pop()
  end
end

function highlightPoint()
	love.graphics.push()
	love.graphics.setLineWidth( lineWidth * 2 )
	love.graphics.setColor( 255, 255, 255 )
	if field.course[ currentWaypointIndex ] then
		love.graphics.circle( "line", field.course[ currentWaypointIndex ].x, field.course[ currentWaypointIndex ].y, 2 )
	end
	for i = 1, 20 do
		if field.course[ currentWaypointIndex - i ] then
			love.graphics.setColor( 255, 0, 0 )
			love.graphics.circle( "line", field.course[ currentWaypointIndex - i ].x, field.course[ currentWaypointIndex - i ].y, 1 )
		end
		if field.course[ currentWaypointIndex + i ] then
			love.graphics.setColor( 0, 255, 0 )
			love.graphics.circle( "line", field.course[ currentWaypointIndex + i ].x, field.course[ currentWaypointIndex + i ].y, 1 )
		end
	end
  love.graphics.pop()
end

function drawPointAsArrow( point ) 
	local triangle = { - 1, 0, 1, 0, 0, 2 }
	love.graphics.push()
	love.graphics.translate( point.x, point.y )
	love.graphics.rotate( point.nextEdge.angle - math.pi / 2 )
	if not point.turnStart and not point.turnEnd then
		love.graphics.polygon( 'line', triangle )
	else
		love.graphics.polygon( 'fill', triangle )
	end
	love.graphics.pop()
end

function drawCoursePoints( course )
  highlightPoint()
	-- course starts green and turns red towards the end
	local colorStep = 256 / #course
	local red, green = 0, 255
  for i, point in ipairs( course ) do
    local ps = love.graphics.getPointSize()
    if point.turnStart then
      love.graphics.setPointSize( ps * 1.2 )
      love.graphics.setColor( 0, 255, 0 )
    elseif point.turnEnd then
      love.graphics.setPointSize( ps * 1.2 )
      love.graphics.setColor( 255, 0, 0 )
    elseif point.headlandCorner then
      love.graphics.setPointSize( ps * 1.2 )
      love.graphics.setColor( 255, 255, 0 )
    elseif point.returnToFirst then
      love.graphics.setPointSize( ps * 1.2 )
      love.graphics.setColor( 255, 255, 255 )
    elseif point.isConnectingTrack then
      love.graphics.setPointSize( ps * 0.5 )
      love.graphics.setColor( 255, 0, 255 )
    elseif point.onIsland then
      love.graphics.setPointSize( ps * 1.5 )
      love.graphics.setColor( 255, 255, 255 )
    elseif point.smoothed and false then
	    love.graphics.setPointSize( ps * 1.5 )
	    love.graphics.setColor( 0, 100, 255 )
    else
      love.graphics.setColor( red, green, 0 )
    end
	  red = red + colorStep
	  green = green - colorStep
    drawPointAsArrow( point )
	  --love.graphics.points( point.x, point.y )
    love.graphics.setPointSize( ps )
    if drawHelpers then
      love.graphics.push()
      love.graphics.scale( 1, -1 )
      if point.text then
        love.graphics.print( point.text, point.x, -point.y, -point.prevEdge.angle + math.pi / 2, 0.2 )
      end
      love.graphics.pop()
      if point.cornerScore and point.cornerScore > 0 then
        love.graphics.circle( "line", point.x, point.y, point.cornerScore )
      end
      if point.deltaAngle and math.abs( point.deltaAngle ) > 0.0 then
        love.graphics.circle( "line", point.x, point.y, math.abs( point.deltaAngle ))
      end
    end
  end
end

-- draw connected headland passes with width
function drawHeadlandPath( object ) 
  if showHeadlandPath and object.headlandPath then
    if object.headlandPath and #object.headlandPath > 0 then
      if showWidth then
        love.graphics.setLineWidth( object.width )
        love.graphics.setColor( 100, 200, 100, 100 )
      else
        love.graphics.setLineWidth( lineWidth * 6 )
        love.graphics.setColor( 00, 200, 00 )
      end
      love.graphics.line( getVertices( object.headlandPath ))
      love.graphics.setLineWidth( lineWidth )
    end
  end
end

function drawField( field )
  if field.loadedBoundaryVertices then
    -- draw field boundary as loaded
    love.graphics.setLineWidth( lineWidth )
    love.graphics.setColor( 100, 100, 100 )
    love.graphics.polygon('line', field.loadedBoundaryVertices)
  end

  if field.calculatedBoundaryVertices then
    -- draw calculated field boundary (if we loaded the field from a course, this 
    -- is the boundary calculated by adding half the implement width to the first headland
    -- track of the course
    love.graphics.setLineWidth( lineWidth )
    love.graphics.setColor( 200, 200, 200 )
    love.graphics.polygon('line', field.calculatedBoundaryVertices)
  end

  drawHeadlandPath( field )
  
  -- draw entire course
  if drawCourse then
    if field.course and #field.course > 1 then
      -- course line
      love.graphics.setColor( 150, 150, 50, 80 )
      --love.graphics.line( getVertices( field.course ))
      love.graphics.setLineWidth( lineWidth )
      -- course points
      love.graphics.setColor( 100, 100, 100 )
      drawCoursePoints( field.course )
      love.graphics.setColor( 100, 100, 100 )
      love.graphics.line( getVertices( field.course ))
      -- start of course, green dot
      love.graphics.setColor( 0, 255, 0, 180 )
      love.graphics.circle( "fill", field.course[ 1 ].x, field.course[ 1 ].y, 5 )
      -- end of course, red dot
      love.graphics.setColor( 255, 0, 0, 180 )
      love.graphics.circle( "fill", field.course[ #field.course ].x, field.course[ #field.course ].y, 5 )

    end
  end

  if ( field.headlandTracks ) then
    if drawConnectingTracks then
      if field.headlandTracks[ #field.headlandTracks ] and field.headlandTracks[ #field.headlandTracks ].connectingTracks then
        -- track connecting blocks
        for i, t in ipairs( field.headlandTracks[ #field.headlandTracks ].connectingTracks ) do
          love.graphics.setColor( 255, 165, 000, 200 )
          love.graphics.setLineWidth( lineWidth * 15 )
          if #t > 1 then love.graphics.line( getVertices( t )) end
          love.graphics.setLineWidth( lineWidth )
        end
      end
    end
  end

  -- draw tracks in field body
  if drawTrack then
    if field.track and #field.track > 1 then
      if showWidth then
        love.graphics.setLineWidth( field.width )
        love.graphics.setColor( 100, 200, 100, 100 )
      else
        love.graphics.setLineWidth( lineWidth )
        love.graphics.setColor( 100, 100, 100 )
      end
      love.graphics.line( getVertices( field.track ))
    end
  end
  if drawHelpers then
    drawMarks( marks )
    drawLines( lines )
    drawPolygon( helperPolygon )
    drawPathFindingHelpers()
	  drawIslands( field.islandNodes )  
  end
	if drawBlocks then
		drawFieldBlocks( field.blocks )
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

function drawIslands( points )
	love.graphics.setLineWidth( lineWidth )
	for i, point in ipairs(field.islandNodes ) do
		local len = 0.4
		love.graphics.setColor( 000, 100, 200 )
		if point.visited then len = 1 end
		love.graphics.line( point.x - len, point.y, point.x + len, point.y )
		love.graphics.line( point.x, point.y - len, point.x, point.y + len )
  end
  if field.islands then
    love.graphics.setColor( 100, 200, 100 )
    for _, island in ipairs( field.islands ) do
      love.graphics.polygon('line', getVertices( island.nodes ))
      if showWidth then
        love.graphics.setLineWidth( field.width )
        love.graphics.setColor( 100, 200, 100, 100 )
      else
        love.graphics.setLineWidth( lineWidth * 6 )
        love.graphics.setColor( 00, 200, 00 )
      end
      for _, headland in ipairs( island.headlandTracks ) do
        love.graphics.setLineWidth( lineWidth )
        love.graphics.line( getVertices( headland ))
      end
      drawHeadlandPath( island )
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
  if showSettings then
    drawSettings()
  end
end

function errorHandler( err )
  print( err )
  print( debug.traceback())
end

function generate()
  -- clear debug graphics
  marks = {}
  lines = {}
  helperPolygon = {}
  status, ok = xpcall( generateCourseForField, errorHandler, 
                                           field, field.width, headlandSettings, field.nTracksToSkip,
                                           field.extendTracks, field.minDistanceBetweenPoints,
                                           math.rad( minSmoothingAngleDeg ), math.rad( headlandSettings.minHeadlandTurnAngleDeg ), field.doSmooth,
                                           field.roundCorners, field.turningRadius,
  										                     true, islandNodes, islandBypassMode, centerSettings
                                           )

  if not status then
    love.window.showMessageBox( "Error", "Could not generate course.", { "Ok" }, "error" )
	elseif not ok then
	  love.window.showMessageBox( "Warning", "Generated course may not be ok.", { "Ok" }, "warning" )
  end
  io.stdout:flush()
end

function love.textinput( t )
  if t == "g" then
    gridSpacing = gridSpacing - 0.5
  end
  if t == "G" then
    gridSpacing = gridSpacing + 0.5
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
    headlandSettings.overlapPercent = headlandSettings.overlapPercent - 5 
    generate()
  end
  if t == "O" then
    headlandSettings.overlapPercent = headlandSettings.overlapPercent + 5 
    generate()
  end
  if t == "P" then
    headlandSettings.nPasses = headlandSettings.nPasses + 1
    generate()
  end
  if t == "p" then
    if headlandSettings.nPasses > 0 then
      headlandSettings.nPasses = headlandSettings.nPasses - 1
      generate()
    end
  end
  if t == "c" then
    headlandSettings.isClockwise = not headlandSettings.isClockwise
    generate()
  end
  if t == "d" then
    field.roundCorners = not field.roundCorners
    generate()
  end
  if t == "t" then
    field.turningRadius = field.turningRadius - 0.5
    generate()
  end
  if t == "T" then
    field.turningRadius = field.turningRadius + 0.5
    generate()
  end
  if t == "h" then
	  if headlandSettings.mode == courseGenerator.HEADLAND_MODE_NORMAL then
		  headlandSettings.mode = courseGenerator.HEADLAND_MODE_LONG_FIELD
	  else
		  headlandSettings.mode = courseGenerator.HEADLAND_MODE_NORMAL
	  end
	  generate()
  end
  if t == "r" then
    headlandSettings.headlandFirst = not headlandSettings.headlandFirst
    generate()
  end
	if t == "q" then
		if centerSettings.useBestAngle then
			centerSettings.useBestAngle = nil
			centerSettings.useLongestEdgeAngle = true
		elseif centerSettings.useLongestEdgeAngle then
			centerSettings.useBestAngle = nil
			centerSettings.useLongestEdgeAngle = nil
		else
			centerSettings.useBestAngle = true
			centerSettings.useLongestEdgeAngle = nil
		end
		generate()
	end
  if t == "A" then
	  centerSettings.rowAngle = centerSettings.rowAngle + math.pi / 16
      generate()
  end
  if t == "a" then
		centerSettings.rowAngle = centerSettings.rowAngle - math.pi / 16
      generate()
  end
  if t == "i" then
    islandBypassMode = islandBypassMode + 1
	  if islandBypassMode > Island.BYPASS_MODE_MAX then
		  islandBypassMode = Island.BYPASS_MODE_MIN
	  end
    islandNodes = ( islandBypassMode ~= Island.BYPASS_MODE_NONE ) and field.islandNodes or {}
    generate()
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
    if minSmoothingAngleDeg > 5 then
      minSmoothingAngleDeg = minSmoothingAngleDeg - 5
      generate()
    end
  end
  if t == ">" then
    minSmoothingAngleDeg = minSmoothingAngleDeg + 5
    generate()
  end
  if t == "k" then
    if headlandSettings.minHeadlandTurnAngleDeg > 5 then
      headlandSettings.minHeadlandTurnAngleDeg = headlandSettings.minHeadlandTurnAngleDeg - 5
      generate()
    end
  end
  if t == "K" then
    headlandSettings.minHeadlandTurnAngleDeg = headlandSettings.minHeadlandTurnAngleDeg + 5
    generate()
  end
  if t == "m" then
    field.doSmooth = not field.doSmooth
    generate()
  end
  if t == "1" then
    drawCourse = not drawCourse
  end
  if t == "2" then
    showHeadlandPath = not showHeadlandPath
  end
  if t == "3" then
    drawConnectingTracks = not drawConnectingTracks
  end
  if t == "4" then
    drawTrack = not drawTrack
  end
  if t == "5" then
    drawHelpers = not drawHelpers
  end
  if t == "6" then
    showSettings = not showSettings
  end
	if t == "7" then
		drawBlocks= not drawBlocks
	end
	if t == "8" then
		drawGrid= not drawGrid
	end
	if t == "9" then
		showWidth = not showWidth
	end
  if t == "=" then
	  currentWaypointIndex = currentWaypointIndex + 1
	  if currentWaypointIndex > #field.course then
		  currentWaypointIndex = 1 
	  end
  end
	if t == "-" then
		currentWaypointIndex = currentWaypointIndex - 1
		if currentWaypointIndex < 1 then
			currentWaypointIndex = #field.course
		end
	end
end

function love.wheelmoved( dx, dy )
  scale = scale + scale * dy * 0.05
  pointSize = pointSize + pointSize * dy * 0.04
end

function love.mousepressed(x, y, button, istouch)
   if button == 1 then 
     leftMouseKeyPressedAt = { x=x, y=y }
     leftMouseKeyPressed = true
     path.from = {}
     path.from.x, path.from.y = love2real( x, y )
     if field.course then
       for i, point in ipairs( field.course ) do
         if math.abs( point.x - path.from.x ) < 1 and math.abs( point.y - path.from.y ) < 1 then
           print( i, point.x, point.y )
           io.stdout:flush()
           break
         end
       end
     end
   end
   if button == 2 then
     cix, ciy = love2real( x, y )
     headlandSettings.startLocation.x = cix
     headlandSettings.startLocation.y = ciy
     generate()
     path.to = {}
     path.to.x, path.to.y = love2real( x, y )
     if path.from then
       print( string.format( "Finding path between %.2f, %.2f and %.2f, %.2f", path.from.x, path.from.y, path.to.x, path.to.y ))
       local now = os.clock()
       path.course, grid = pathFinder.findPath( path.from, path.to , field.boundary, nil, nil, nil )-- pathFinder.addFruitDistanceFromBoundary )
       reversePath.course, grid = pathFinder.findPath( path.to, path.from, field.boundary, nil, nil, nil )--pathFinder.addFruitDistanceFromBoundary )
       print( string.format( "Pathfinding ran for %.2f seconds", os.clock() - now ))
       io.stdout:flush()
       if path.course ~= nil then path.course = path.course end
       if reversePath.course ~= nil then reversePath.course = reversePath.course end
     end
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
  -- show point info
  local rx, ry = love2real( x, y )
  if field.course then
    for i, point in ipairs( field.course ) do
      if math.abs( point.x - rx ) < 1 and math.abs( point.y - ry ) < 1 then
        currentWaypointIndex = i
        break
      end
    end
  end
end
