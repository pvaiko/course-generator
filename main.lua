dofile( 'include.lua' )
profile = require("profile")

local field = {}
marks = {}
lines = {}
local helperPolygon = {}
local headlandSettings = {}
local pointSize = 1
local lineWidth = 0.1
local scale = 1.0
local xOffset, yOffset = 10000, 10000
local windowWidth = 1400
local windowHeight = 950
local showWidth = false
local currentWaypointIndex = 1
local offset = 0
local multiTool = 0
local width = 6

local pathFinder = HybridAStarWithAStarInTheMiddle(20)

local drawConnectingTracks = true
local drawCourse = true
local showHeadlandPath = true 
local drawTrack = false
local drawBlocks = true
local drawGrid = true
local drawHelpers = true
local showSettings = true
local symmetricLaneChange = false

local islandBypassMode = Island.BYPASS_MODE_CIRCLE
--headlandSettings.mode = courseGenerator.HEADLAND_MODE_TWO_SIDE
headlandSettings.mode = courseGenerator.HEADLAND_MODE_NORMAL
--headlandSettings.mode = courseGenerator.HEADLAND_MODE_NARROW_FIELD
headlandSettings.headlandFirst = true
headlandSettings.nPasses = 3
local centerSettings = { mode = courseGenerator.CENTER_MODE_LANDS, useBestAngle = true, useLongestEdgeAngle = false,
                         rowAngle = 0, nRowsToSkip = 0, nRowsPerLand = 6, pipeOnLeftSide = false }

local turnRadius = 6
local extendTracks = 0
local minDistanceBetweenPoints = 0.5
local minSmoothingAngleDeg = 25

-- pathfinding
local path = {}
local reversePath = {}
local gridSpacing = 4.07
local islandNodes = {}
local vehicle


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
  end

  islandNodes = field.islandNodes
  field.loadedBoundaryVertices = getVertices( field.boundary )
  headlandSettings.startLocation = {x=field.boundary[ 1 ].x, y=field.boundary[ 1 ].y}

	love.keyboard.setKeyRepeat(true)
	vehicle = Vehicle(headlandSettings.startLocation.x, -headlandSettings.startLocation.y, 0)

  headlandSettings.overlapPercent = 7
  headlandSettings.minHeadlandTurnAngleDeg = 45
  field.doSmooth = true
  headlandSettings.isClockwise = true
  field.roundCorners = false
  if arg[ 2 ] == "fromCourse" then
    -- use the outermost headland path as the basis of the 
    -- generation, that is, the field.boundary is actually
    -- a headland pass of a course
    -- calculate the boundary from the headland track
    field.boundary = calculateHeadlandTrack( field.boundary, courseGenerator.HEADLAND_MODE_NORMAL, field.boundary.isClockwise,width / 2,
                                             minDistanceBetweenPoints, math.rad( minSmoothingAngleDeg), 0,
                                             field.doSmooth, false, turnRadius, nil, nil )
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

    drawPathFinderNodes()
    -- for text, don't flip y axis as it results in mirrored characters
    love.graphics.push()
    love.graphics.setLineWidth( 1 )
    love.graphics.setColor(0, 40, 140 )
    if path.course and #path.course > 2 then
        love.graphics.line( getVertices( path.course ))
        love.graphics.setColor(0, 120, 200 )
        love.graphics.points( getVertices( path.course ))
    end
    if reversePath.course and #reversePath.course > 2 then
        love.graphics.line( getVertices( reversePath.course ))
        love.graphics.setColor( 220, 100, 0 )
        love.graphics.points( getVertices( reversePath.course ))
    end
    if path.grid and drawGrid then
        love.graphics.setLineWidth( lineWidth )
        for i, point in ipairs( path.grid ) do
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
  love.graphics.print( string.format( "HEADLAND %s, width: %.1f m, overlap %d%% number of passes: %d, direction %s, corners: %s, radius: %.1f",
           courseGenerator.headlandModeTexts[headlandSettings.mode], width, headlandSettings.overlapPercent, headlandSettings.nPasses, headlandDirection, roundCorners, turnRadius), 10, 30, 0, 1 )
  love.graphics.print( string.format( "CENTER mode: %s, skipping %d tracks, extend %d m",
           courseGenerator.centerModeTexts[centerSettings.mode], centerSettings.nRowsToSkip, extendTracks ), 10, 50, 0, 1 )
           
  local smoothingStatus 
  if field.doSmooth then smoothingStatus = "on" else smoothingStatus = "off" end
  
  love.graphics.print( string.format( "min point distance: %.2f m, corner smoothing: %s, min. smoothing angle: %d, min. headland turn angle = %d", 
    minDistanceBetweenPoints, smoothingStatus, minSmoothingAngleDeg, headlandSettings.minHeadlandTurnAngleDeg ), 10, 70, 0, 1 )
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
        love.graphics.print(string.format("pass=%s track =%s(%s) r=%s adj=%s rm=%s islandbp=%s",
					tostring( pass), tostring( track ), tostring( origTrack ), radius, adjacentToIsland, tostring( ridgeMarker ), tostring(cWp.islandBypass)),
          windowWidth - 400, windowHeight - 20, 0, 1)

      end
  end

	love.graphics.print(string.format("v=%.1f x=%.1f y=%.1f h=%.0f° sa=%.1f° r=%.1f",
		vehicle.speed, vehicle.position.x, -vehicle.position.z, math.deg(vehicle.position.yRotation),
		math.deg(vehicle.steeringAngle), vehicle.turningRadius),
		windowWidth - 300, windowHeight - 60, 0, 1)

  -- help text
  local y = windowHeight - 380
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
  love.graphics.print( "o/O - left/right offset", 10, y, 0, 1 )
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
	love.graphics.print( "j/J - -/+ up/down rows to skip", 10, y, 0, 1 )
  y = y + 20
	love.graphics.print( "l - toggle center mode", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "i - toggle island bypass mode", 10, y, 0, 1 )
  y = y + 20
    love.graphics.print( "y - toggle symmetric lane change", 10, y, 0, 1 )
    y = y + 20
  love.graphics.print( "g - generate course", 10, y, 0, 1 )
  y = y + 20
  love.graphics.print( "s - save course", 10, y, 0, 1 )
  love.graphics.pop()
end

function drawMarks( points )
  love.graphics.setColor( 200, 200, 0 )
  for i, point in pairs( points ) do
    love.graphics.circle( "fill", point.x, point.y, 1 )
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
	local left, right = -0.8, 0.8
	if point.ridgeMarker then
		if point.ridgeMarker == 1 then
			right = 0
		else
			left = 0
		end
	end
	local triangle = { left, 0, right, 0, 0, 1.6 }
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

  --drawHeadlandPath( field )
	drawHeadlandTracks()
  
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
        love.graphics.setLineWidth( width )
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
        love.graphics.setLineWidth( width )
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

function drawPathFinderNodes()
    if pathFinder and pathFinder.nodes then
        for _, row in pairs(pathFinder.nodes.nodes) do
            for _, column in pairs(row) do
                for _, cell in pairs(column) do
                    if cell.pred == cell then
                        love.graphics.setPointSize(5)
                        love.graphics.setColor( 0, 100, 100 )
                    else
                        local range = pathFinder.nodes.highestCost - pathFinder.nodes.lowestCost
                        local color = (cell.cost - pathFinder.nodes.lowestCost) * 250 / range
                        love.graphics.setPointSize(1)
                        if cell:isClosed() or true then
                            love.graphics.setColor(100 + color, 250 - color, 0 )
                        else
                            love.graphics.setColor( cell.cost *3, 80, 0 )
                        end
                    end
                    if cell.pred then
                        love.graphics.setLineWidth(0.1)
                        love.graphics.line(cell.x, cell.y, cell.pred.x, cell.pred.y)
                    else
                        love.graphics.setPointSize(3)
                        love.graphics.points(cell.x, cell.y)
                    end

                end
            end
        end
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
    vehicle:draw()
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
    headlandSettings.width = width
    centerSettings.width = width

    status, ok = xpcall( generateCourseForField, errorHandler,
                                           field, width, headlandSettings,
                                           extendTracks, minDistanceBetweenPoints,
                                           math.rad( minSmoothingAngleDeg ), math.rad( headlandSettings.minHeadlandTurnAngleDeg ), field.doSmooth,
                                           field.roundCorners, turnRadius,
  										                     false, islandNodes, islandBypassMode, centerSettings
                                           )

  if not status then
    love.window.showMessageBox( "Error", "Could not generate course.", { "Ok" }, "error" )
	elseif not ok then
	  love.window.showMessageBox( "Warning", "Generated course may not be ok.", { "Ok" }, "warning" )
  end
	if field.course then
		for i = 2, #field.course - 1 do
			local cp, pp, np = field.course[ i ], field.course[ i - 1 ], field.course[ i + 1 ]
			local dA = math.abs( getDeltaAngle( pp.nextEdge.angle, pp.prevEdge.angle ))+
				math.abs( getDeltaAngle( cp.prevEdge.angle, cp.nextEdge.angle ))
			-- the direction changes a lot over two points, this is a glitch
			if dA > math.rad(270) and not pp.reverse then
				print( 'THERE IS A GLITCH AT POINT ', i )
				cp.text = "GLITCH"
				table.insert(marks, {x = cp.x, y = cp.y})
			end
		end
	end
    if multiTool > 1 and offset ~= 0 then
        marks = {}
        local course = Course.createFromGeneratedCourse({}, field.course)
        local offsetCourse = course:calculateOffsetCourse(multiTool, offset, width / multiTool, symmetricLaneChange)
        field.course = Polygon:new(courseGenerator.pointsToXyInPlace(offsetCourse.waypoints))
        field.course:calculateData()
    end
	io.stdout:flush()
end
function love.keypressed(key, scancode, isrepeat)
	if key == 'up' then
		vehicle:accelerate()
	elseif key == 'down' then
		vehicle:deccelerate()
	elseif key == 'left' then
		vehicle:turnLeft()
	elseif key == 'right' then
		vehicle:turnRight()
	end
end

function love.textinput(key)
    if key == "g" then
        gridSpacing = gridSpacing - 0.5
    elseif key == "G" then
        gridSpacing = gridSpacing + 0.5
    elseif key == "s" then
        saveFile()
    elseif key == "W" then
        width = width + 0.1
        generate()
    elseif key == "w" then
        width = width - 0.1
        generate()
    elseif key == "X" then
        extendTracks = extendTracks + 1
        generate()
    elseif key == "x" then
        extendTracks = extendTracks - 1
        generate()
    elseif key == "o" then
        offset = offset - 1
        generate()
    elseif key == "O" then
        offset = offset + 1
        generate()
    elseif key == "P" then
        headlandSettings.nPasses = headlandSettings.nPasses + 1
        generate()
    elseif key == "p" then
        if headlandSettings.nPasses > 0 then
            headlandSettings.nPasses = headlandSettings.nPasses - 1
            generate()
        end
    elseif key == "c" then
        headlandSettings.isClockwise = not headlandSettings.isClockwise
        generate()
    elseif key == "d" then
        field.roundCorners = not field.roundCorners
        generate()
    elseif key == "t" then
        turnRadius = turnRadius - 0.5
        generate()
    elseif key == "T" then
        turnRadius = turnRadius + 0.5
        generate()
    elseif key == "h" then
        headlandSettings.mode = headlandSettings.mode + 1
        if headlandSettings.mode > courseGenerator.HEADLAND_MODE_MAX then
            headlandSettings.mode = courseGenerator.HEADLAND_MODE_MIN
        end
        generate()
    elseif key == "H" then
        headlandSettings.mode = headlandSettings.mode - 1
        if headlandSettings.mode < courseGenerator.HEADLAND_MODE_MIN then
            headlandSettings.mode = courseGenerator.HEADLAND_MODE_MAX
        end
        generate()
    elseif key == "l" then
        centerSettings.mode = centerSettings.mode + 1
        if centerSettings.mode > courseGenerator.CENTER_MODE_MAX then
            centerSettings.mode = courseGenerator.CENTER_MODE_MIN
        end
        generate()
    elseif key == "L" then
        centerSettings.mode = centerSettings.mode - 1
        if centerSettings.mode < courseGenerator.CENTER_MODE_MIN then
            centerSettings.mode = courseGenerator.CENTER_MODE_MAX
        end
        generate()
    elseif key == "r" then
        headlandSettings.headlandFirst = not headlandSettings.headlandFirst
        generate()
    elseif key == "q" then
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
    elseif key == "A" then
        centerSettings.rowAngle = centerSettings.rowAngle + math.pi / 16
        generate()
    elseif key == "a" then
        centerSettings.rowAngle = centerSettings.rowAngle - math.pi / 16
        generate()
    elseif key == "J" then
        centerSettings.nRowsToSkip = centerSettings.nRowsToSkip + 1
        generate()
    elseif key == "j" then
        if centerSettings.nRowsToSkip > 0 then
            centerSettings.nRowsToSkip = centerSettings.nRowsToSkip - 1
            generate()
        end
    elseif key == "i" then
        islandBypassMode = islandBypassMode + 1
        if islandBypassMode > Island.BYPASS_MODE_MAX then
            islandBypassMode = Island.BYPASS_MODE_MIN
        end
        islandNodes = ( islandBypassMode ~= Island.BYPASS_MODE_NONE ) and field.islandNodes or {}
        generate()
    elseif key == "," then
        if minDistanceBetweenPoints > 0.25 then
            minDistanceBetweenPoints = minDistanceBetweenPoints - 0.25
            generate()
        end
    elseif key == "<" then
        minDistanceBetweenPoints = minDistanceBetweenPoints + 0.25
        generate()
    elseif key == "." then
        if minSmoothingAngleDeg > 5 then
            minSmoothingAngleDeg = minSmoothingAngleDeg - 5
            generate()
        end
    elseif key == ">" then
        minSmoothingAngleDeg = minSmoothingAngleDeg + 5
        generate()
    elseif key == "k" then
        if headlandSettings.minHeadlandTurnAngleDeg > 5 then
            headlandSettings.minHeadlandTurnAngleDeg = headlandSettings.minHeadlandTurnAngleDeg - 5
            generate()
        end
    elseif key == "K" then
        headlandSettings.minHeadlandTurnAngleDeg = headlandSettings.minHeadlandTurnAngleDeg + 5
        generate()
    elseif key == "m" then
        field.doSmooth = not field.doSmooth
        generate()
    elseif key == "y" then
        symmetricLaneChange = not symmetricLaneChange
        generate()
    elseif key == "1" then
        drawCourse = not drawCourse
    elseif key == "2" then
        showHeadlandPath = not showHeadlandPath
    elseif key == "3" then
        drawConnectingTracks = not drawConnectingTracks
    elseif key == "4" then
        drawTrack = not drawTrack
    elseif key == "5" then
        drawHelpers = not drawHelpers
    elseif key == "6" then
        showSettings = not showSettings
    elseif key == "7" then
        drawBlocks= not drawBlocks
    elseif key == "8" then
        drawGrid= not drawGrid
    elseif key == "9" then
        showWidth = not showWidth
    elseif key == "=" then
        currentWaypointIndex = currentWaypointIndex + 1
        if currentWaypointIndex > #field.course then
            currentWaypointIndex = 1
        end
        if love.keyboard.isDown('lctrl') then
            -- move vehicle to the current waypoitn
            vehicle:setPosition(field.course[currentWaypointIndex].x, -field.course[currentWaypointIndex].y)
            vehicle:setRotation(field.course[currentWaypointIndex].nextEdge.angle)
        end
    elseif key == "-" then
        currentWaypointIndex = currentWaypointIndex - 1
        if currentWaypointIndex < 1 then
            currentWaypointIndex = #field.course
        end
        if love.keyboard.isDown('lctrl') then
            vehicle:setPosition(field.course[currentWaypointIndex].x, -field.course[currentWaypointIndex].y)
            vehicle:setRotation(field.course[currentWaypointIndex].nextEdge.angle)
        end
    end
end

function love.wheelmoved( dx, dy )
  scale = scale + scale * dy * 0.05
  pointSize = pointSize + pointSize * dy * 0.04
end

function love.mousepressed(x, y, button, istouch)
	if button == 1 then
		local x, y = love2real( x, y )
		local ix = findWaypointIndexForPosition(x, y)
        if love.keyboard.isDown('lctrl') then
            -- place vehicle on the clicked position
            vehicle:setPosition(x, -y)
            -- and to the rotation
            if ix then
                vehicle:setRotation(field.course[ix].nextEdge.angle)
            end
        elseif love.keyboard.isDown('lshift') then
            if ix then
                vehicle:setTarget(Point(x, -y, field.course[ix].nextEdge.angle))
            end
        else
            dragging = true
        end

	end
	if button == 2 then
		cix, ciy = love2real( x, y )
		headlandSettings.startLocation.x = cix
		headlandSettings.startLocation.y = ciy
		-- right mouse button: generate course
		-- with left shift: generate headland path
		-- with right CTRL: generate field path
		if not love.keyboard.isDown('lshift') and not love.keyboard.isDown('lctrl') then
			generate()
		else
			path.to = {}
			path.to.x, path.to.y = love2real( x, y )
			path.from = vehicle:getXYPosition()
			if path.from then
				print( string.format( "Finding path between %.2f, %.2f and %.2f, %.2f", path.from.x, path.from.y, path.to.x, path.to.y ))
				path.started = os.clock()
				if love.keyboard.isDown('lctrl') then
					--path.done, path.course, path.grid = pathFinder:start( path.from, path.to , field.boundary, nil, nil, true)
                    local start = State3D(path.from.x, path.from.y, 0)
                    local goal = State3D(path.to.x, path.to.y, math.pi)
--					path.done, path.course, path.grid = pathFinder:start( start, goal, turnRadius, false, field.boundary, getIslandPenalty)
					--path.done, reversePath.course, path.grid = reversePathfinder:start( path.to, path.from, field.boundary, nil, nil, false)
				else
--					path.course, path.grid = headlandPathfinder:findPath(path.from, path.to , field.headlandTracks, width, true)
				end
				io.stdout:flush()
			end
		end
	end
end

function love.mousereleased(x, y, button, istouch)
   if button == 1 then 
      dragging = false
   end
end

function love.mousemoved( x, y, dx, dy )
  if dragging then
    xOffset = xOffset + dx
    yOffset = yOffset - dy
  end
  -- show point info
  local rx, ry = love2real( x, y )
	currentWaypointIndex = findWaypointIndexForPosition(rx, ry) or currentWaypointIndex
end

function findWaypointIndexForPosition(rx, ry)
	if field.course then
		for i, point in ipairs( field.course ) do
			if math.abs( point.x - rx ) < 1 and math.abs( point.y - ry ) < 1 then
				return i
			end
		end
	end
	return nil
end

function getIslandPenalty(node)
    for _, point in ipairs(field.islandNodes ) do
        local dx = node.x - point.x
        local dy = node.y - point.y
        local d2 = dx * dx + dy * dy
        if d2 < 9 then
            return 100
        end
    end
    return 0
end

function love.update(dt)
	-- limit frame rate (and thus CPU usage), my laptop likes that on long flights)
	if dt < 1/10 then
		love.timer.sleep(1/10 - dt)
	end
	--vehicle:update(dt)
	if pathFinder:isActive() then
		path.done, path.course, path.grid = pathFinder:resume()
		if path.done then
			print( string.format( "Pathfinding ran for %.2f seconds", os.clock() - path.started ))
			if path.course then
				print(string.format('Path found, %d waypoints', #path.course))
			else
				print('Path not found')
			end
			--profile.stop()
			--print(profile.report('time', 10))
			io.stdout:flush()
		end
	end
	--if reversePathfinder:isActive() then
	--	path.done, reversePath.course, path.grid = reversePathfinder:resume()
	--end
end