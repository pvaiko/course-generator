--
-- Functions to manipulate tracks 
--
--
-- how close the vehicle must be to the field to automatically 
-- calculate a track starting near the vehicle's location
-- This is in meters
maxDistanceFromField = 30

-- Distance of waypoints on the generated track in meters
waypointDistance = 5

-- Enable generating parallel tracks which intersect a field boundary
-- more than twice: that is, try to fit the tracks into a concave field
enableSplitTracks = true
  
require( 'geo' )
require( 'bspline' )

local rotatedMarks = {}
--- Generate course for a field.
-- The result will be:
-- field.headlandPath 
--   array of points containing all headland passes
-- field.headlandTracks[ nHeadlandPasses ].pathFromHeadlandToCenter 
--   this is the path from the end of the innermost headland track to the start
--   of the parallel tracks in the middle of the field.
-- field.track
--   parallel tracks in the middle of the field.
--
-- field
--
-- implementWidth width of the implement
-- 
-- nHeadlandPasses number of headland passes to generate
--
-- overlapPercent headland pass overlap in percent, may reduce skipped fruit in corners
--
-- useBoundaryAsFirstHeadlandPass field.boundary above is the first headland pass. True 
--   when generating based on an existing course. 
--   
-- nTracksToSkip center tracks to skip. When 0, normal alternating tracks are generated
--   when > 0, intermediate tracks are skipped to allow for wider turns
--
-- extendTracks extend center tracks into the headland (meters) to prevent unworked
--   triangles with long plows.
--
function generateCourseForField( field, implementWidth, nHeadlandPasses, overlapPercent, 
                                 useBoundaryAsFirstHeadlandPass, nTracksToSkip, extendTracks,
                                 minDistanceBetweenPoints, angleThreshold, doSmooth )
  rotatedMarks = {}
  field.boundingBox = getBoundingBox( field.boundary )
  calculatePolygonData( field.boundary )
  field.headlandTracks = {}
  local startHeadlandPass
  if useBoundaryAsFirstHeadlandPass then
    field.headlandTracks[ 1 ] = field.boundary 
    startHeadlandPass = 2
  else
    startHeadlandPass = 1
  end
  local previousTrack = field.boundary
  for j = startHeadlandPass, nHeadlandPasses do
    local width
    if j == 1 then 
      width = implementWidth / 2
    else 
      width = implementWidth
    end
    field.headlandTracks[ j ] = calculateHeadlandTrack( previousTrack, width - width * overlapPercent / 100, 
                                                        minDistanceBetweenPoints, angleThreshold, 0, doSmooth )
    previousTrack = field.headlandTracks[ j ]
  end
  linkHeadlandTracks( field, implementWidth )
  field.track = generateTracks( field.headlandTracks[ nHeadlandPasses ], implementWidth, nTracksToSkip, extendTracks )
  field.bestAngle = field.headlandTracks[ nHeadlandPasses ].bestAngle
  field.nTracks = field.headlandTracks[ nHeadlandPasses ].nTracks
  -- assemble complete course now
  field.course = {}
  for i, point in ipairs( field.headlandPath ) do
    table.insert( field.course, point )
  end
  for i, point in ipairs( field.headlandTracks[ #field.headlandTracks ].pathFromHeadlandToCenter ) do
    table.insert( field.course, point )
  end
  for i, point in ipairs( field.track ) do
    table.insert( field.course, point )
  end
  calculatePolygonData( field.course )
end

--- Calculate a headland track inside polygon in offset distance
function calculateHeadlandTrack( polygon, targetOffset, minDistanceBetweenPoints, angleThreshold, currentOffset, doSmooth )
  -- recursion limit
  if currentOffset == 0 then 
    n = 1
  else
    n = n + 1
  end
  if currentOffset >= targetOffset or n > 50 then return polygon end
  -- we'll use the grassfire algorithm and approach the target offset by 
  -- iteration, generating headland tracks close enough to the previous one
  -- so the resulting offset polygon is always clean (its edges don't intersect
  -- each other)
  -- this can be ensured by choosing an offset small enough
  local deltaOffset = polygon.shortestEdgeLength / 2
  deltaOffset = math.min( deltaOffset, targetOffset - currentOffset )
  local offsetEdges = {} 
  for i, point in ipairs( polygon ) do
    local newEdge = {} 
    local newFrom = addPolarVectorToPoint( point.nextEdge.from, point.nextEdge.angle + getInwardDirection( polygon.isClockwise ), deltaOffset )
    local newTo = addPolarVectorToPoint( point.nextEdge.to, point.nextEdge.angle + getInwardDirection( polygon.isClockwise ), deltaOffset )
    table.insert( offsetEdges, { from=newFrom, to=newTo })
  end
 
  local vertices = {} 
  for i, edge in ipairs( offsetEdges ) do
    local ix = i - 1
    if ix == 0 then ix = #offsetEdges end
    local prevEdge = offsetEdges[ix ]
    local vertex = getIntersection( edge.from.x, edge.from.y, edge.to.x, edge.to.y, 
                                    prevEdge.from.x, prevEdge.from.y, prevEdge.to.x, prevEdge.to.y )
    if vertex then
      table.insert( vertices, vertex )
    else
      if getDistanceBetweenPoints( prevEdge.to, edge.from ) < minDistanceBetweenPoints then
        local x, y = getPointInTheMiddle( prevEdge.to, edge.from )
        table.insert( vertices, { x=x, y=y })
      else
        table.insert( vertices, prevEdge.to )
        table.insert( vertices, edge.from )
      end
    end
  end
  calculatePolygonData( vertices )
  if doSmooth then
    vertices = smooth( vertices, angleThreshold, 1 )
  end
  -- only filter points too close, don't care about angle
  applyLowPassFilter( vertices, math.pi, minDistanceBetweenPoints )
  return calculateHeadlandTrack( vertices, targetOffset, minDistanceBetweenPoints, angleThreshold, 
                                 currentOffset + deltaOffset, doSmooth )
end

--- This makes sense only when these turns are implemented in Coursplay.
-- as of now, it'll generate nice turns only for 180 degree 
function addTurnsToCorners( vertices, angleThreshold )
  local ix = function( a ) return getPolygonIndex( vertices, a ) end
  i = 1
  while i < #vertices do
    local cp = vertices[ i ]
    local np = vertices[ ix( i + 1 )]
    if math.abs( getDeltaAngle( np.nextEdge.angle, cp.nextEdge.angle )) > angleThreshold then
      cp.turnStart = true
      np.turnEnd = true
      i = i + 2
    end
    i = i + 1
  end
end

--- Reverse a course. This is to build a sowing/cultivating etc. course
-- from a harvester course.
-- We build our courses working from the outside inwards (harverster).
-- This function reverses that course so it can be used for fieldwork
-- starting in the middle of the course.
--
function reverseCourse( course )
  local result = {}
  for i = #course, 1, -1 do
    local newPoint = copyPoint( course[ i ])
    if newPoint.turnStart then
      newPoint.turnStart = nil
      newPoint.turnEnd = true
    elseif newPoint.turnEnd then
      newPoint.turnEnd = nil
      newPoint.turnStart = true
    end
    table.insert( result, newPoint )
  end
  calculatePolygonData( result )
  return result
end

--- Link the generated, parallel circular headland tracks to
-- a single spiral track
-- First, We have to find where to start our course. 
--  If we work on the headland first:
--  - the starting point will be on the outermost headland track
--    close to the current vehicle position. The vehicle's heading 
--    is used to decide the direction, clockwise or counterclockwise
--  - for the subsequent headland passes, we add a 90 degree vector 
--    to the first point of the first pass and then continue from there
--    inwards
--
function linkHeadlandTracks( field, implementWidth )
  -- first, find the intersection of the outermost headland track and the 
  -- vehicles heading vector. 
  local startLocation = field.vehicle.location
  local heading = math.rad( field.vehicle.heading )
  local distance = maxDistanceFromField 
  local headlandPath = {}
  vectors = {}
  for i = 1, #field.headlandTracks do
    --table.insert( vectors, { startLocation, addPolarVectorToPoint( startLocation, heading, distance )})

    -- we may have an issue finding the next track around corners, so try a couple of other headings
    local headings = { heading, heading + math.pi / 3, heading - math.pi / 3 }
    local fromIndex, toIndex
    local found = false
    for _, h in pairs( headings ) do
      fromIndex, toIndex = getIntersectionOfLineAndPolygon( field.headlandTracks[ i ], startLocation, 
                           addPolarVectorToPoint( startLocation, h, distance ))
      if fromIndex then
        -- now find out which direction we have to drive on the headland pass.
        -- This depends on the order of the points in the polygon: clockwise or 
        -- counterclockwise. Basically we have to know if we follow the points
        -- of the polygon in increasing or decreasing index order. So, if 
        -- fromIndex (the smaller one) is closer to us, we need to follow
        -- the points as they defined in the polygon. Otherwise it is the 
        -- reverse order.
        local distanceFromFromIndex = getDistanceBetweenPoints( field.headlandTracks[ i ][ fromIndex ], field.vehicle.location )
        local distanceFromToIndex = getDistanceBetweenPoints( field.headlandTracks[ i ][ toIndex ], field.vehicle.location )
        if distanceFromToIndex < distanceFromFromIndex then
          -- must reverse direction
          -- driving direction is in decreasing index, so we start at fromIndex and go a full circle
          -- to toIndex 
          addTrackToHeadlandPath( headlandPath, field.headlandTracks[ i ], i, fromIndex, toIndex, -1 )
          startLocation = field.headlandTracks[ i ][ fromIndex ]
          field.headlandTracks[ i ].circleStart = fromIndex
          field.headlandTracks[ i ].circleEnd = toIndex 
          field.headlandTracks[ i ].circleStep = -1
        else
          -- driving direction is in increasing index, so we start at toIndex and go a full circle
          -- back to fromIndex
          addTrackToHeadlandPath( headlandPath, field.headlandTracks[ i ], i, toIndex, fromIndex, 1 )
          startLocation = field.headlandTracks[ i ][ toIndex ]
          field.headlandTracks[ i ].circleStart = toIndex
          field.headlandTracks[ i ].circleEnd = fromIndex 
          field.headlandTracks[ i ].circleStep = 1
        end
        heading = field.headlandTracks[ i ][ fromIndex ].tangent.angle + getInwardDirection( field.headlandTracks[ i ].isClockwise )
        --v = { location = startLocation, heading=math.deg( heading ) }
        -- remember this, we'll need when generating the link from the last headland pass
        -- to the parallel tracks
        table.insert( rotatedMarks, field.headlandTracks[ i ][ fromIndex ])
        table.insert( rotatedMarks, field.headlandTracks[ i ][ toIndex ])
        break
      else
        print( string.format( "Could not link headland track %d at heading %.2f", i, math.deg( h )))
        io.stdout:flush()
      end
    end
  end
  field.headlandPath = headlandPath
end

--- add a series of points (track) to the headland path. This is to 
-- assemble the complete spiral headland path from the individual 
-- parallel headland tracks.
function addTrackToHeadlandPath( headlandPath, track, passNumber, from, to, step)
  for i, point in polygonIterator( track, from, to, step ) do
    table.insert( headlandPath, track[ i ])
    headlandPath[ #headlandPath ].passNumber = passNumber
  end
end

--- Find the best angle to use for the tracks in a field.
--  The best angle results in the minimum number of tracks
--  (and thus, turns) needed to cover the field.
function findBestTrackAngle( field, width )
  local minConvexTracks = 10000
  local minNonConvexTracks = 10000
  local bestConvexAngle = nil
  local bestNonConvexAngle = nil
  for angle = 0, 180, 1 do
    local rotated = rotatePoints( field, math.rad( angle ))
    local tracks = generateParallelTracks( rotated, width )
    local nFullTracks, nSplitTracks = countTracks( tracks )
    local nTotalTracks = nFullTracks + nSplitTracks
    if nFullTracks < minConvexTracks and nSplitTracks == 0 then
      minConvexTracks = nTotalTracks
      bestConvexAngle = angle
    elseif nTotalTracks < minNonConvexTracks and nSplitTracks ~= 0 then
      minNonConvexTracks = nTotalTracks
      bestNonConvexAngle = angle
    end
  end
  local bestAngle, minTracks
  if bestConvexAngle then 
    print( "Best convex angle: " .. bestConvexAngle .. " tracks: " .. minConvexTracks )
    bestAngle = bestConvexAngle
    minTracks = minConvexTracks
  end
  if bestNonConvexAngle then 
    print( "Best non-convex angle: " .. bestNonConvexAngle .. " total tracks: " .. minNonConvexTracks )
    if bestConvexAngle then
      -- there is a convex solution to this field, use that unless the non-convex is 
      -- significantly better
      if ( minConvexTracks - minNonConvexTracks ) > minConvexTracks * 0.2 then
        bestAngle = bestNonConvexAngle
        minTracks = minNonConvexTracks
        print( "Non-convex seems better." )
      else
        bestAngle = bestConvexAngle
        minTracks = minConvexTracks
        print( "Convex seems better" )
      end
    else
      -- only non-convex solution
      bestAngle = bestNonConvexAngle
      minTracks = minNonConvexTracks
      print( "Has no convex solution, going with non-convex" )
    end
  end
  return bestAngle, minTracks
end

--- Generate up/down tracks covering a field at the optimum angle
function generateTracks( field, width, nTracksToSkip, extendTracks )
  -- translate field so we can rotate it around its center. This way all points
  -- will be approximately the same distance from the origo and the rotation calculation
  -- will be more accurate
  local bb = getBoundingBox( field )
  local dx, dy = ( bb.maxX + bb.minX ) / 2, ( bb.maxY + bb.minY ) / 2 
  local translated = translatePoints( field, -dx , -dy )
  -- Now, determine the angle where the number of tracks is the minimum
  field.bestAngle, field.nTracks = findBestTrackAngle( translated, width )
  if not field.bestAngle then
    field.bestAngle = field.bestDirection.dir
    print( "No best angle found, use the longest edge direction " .. field.bestAngle )
  end
  -- now, generate the tracks according to the implement width within the rotated field's bounding box
  -- using the best angle
  local rotated = rotatePoints( translated, math.rad( field.bestAngle ))

  local parallelTracks = generateParallelTracks( rotated, width )

  local blocks = {}
  blocks = splitCenterIntoBlocks( parallelTracks, blocks )

  for i, block in ipairs( blocks ) do
    for _, j in ipairs({ 1, #block }) do
      table.insert( rotatedMarks, block[ j ].intersections[ 1 ])
      rotatedMarks[ #rotatedMarks ].label = string.format( "%d-%d/1", i, j )
      table.insert( rotatedMarks, block[ j ].intersections[ 2 ])
      rotatedMarks[ #rotatedMarks ].label = string.format( "%d-%d/2", i, j )
    end
    print( string.format( "Block %d has %d tracks", i, #block ))
    block.tracksWithWaypoints = addWaypointsToTracks( block, width, extendTracks )
    block.covered = false
    io.stdout:flush()
  end
  
  -- We now have split the area within the headland into blocks. If this is 
  -- a convex field, there is only one block, non-convex ones may have multiple
  -- blocks. 
  -- Now we have to connect the first block with the end of the headland track
  -- and then connect each block so we cover the entire field.

  local startIx, endIx, step = field.circleStart, field.circleEnd, field.circleStep
  local workedBlocks = {} 
  while startIx do
    startIx, endIx, block = findTrackToNextBlock( blocks, rotated, startIx, endIx, step )
    io.stdout:flush()
    table.insert( workedBlocks, block )
  end

  -- workedBlocks has now a the list of blocks we need to work on, including the track
  -- leading to the block from the previous block or the headland.
  local track = {}
  local connectingTracks = {}
  for i, block in ipairs( workedBlocks ) do
    connectingTracks[ i ] = {}
    for j = 1, #block.trackToThisBlock do
      table.insert( track, block.trackToThisBlock[ j ])
      table.insert( connectingTracks[ i ], block.trackToThisBlock[ j ])
    end
    linkParallelTracks( track, block.tracksWithWaypoints, block.bottomToTop, block.leftToRight, nTracksToSkip ) 
  end
  
  -- now rotate and translate everything back to the original coordinate system
  rotatedMarks = translatePoints( rotatePoints( rotatedMarks, -math.rad( field.bestAngle )), dx, dy )
  for i = 1, #rotatedMarks do
    table.insert( marks, rotatedMarks[ i ])
  end
  for i = 1, #connectingTracks do
    connectingTracks[ i ] = translatePoints( rotatePoints( connectingTracks[ i ], -math.rad( field.bestAngle )), dx, dy )
  end
  field.connectingTracks = connectingTracks
  field.pathFromHeadlandToCenter = 
    translatePoints( rotatePoints( workedBlocks[ 1 ].trackToThisBlock, -math.rad( field.bestAngle )), dx, dy )
  return translatePoints( rotatePoints( track, -math.rad( field.bestAngle )), dx, dy )
end

----------------------------------------------------------------------------------
-- Functions below work on a field rotated so that all parallel tracks are 
-- horizontal ( y = constant ). This makes track calculation really easy.
----------------------------------------------------------------------------------

--- Generate a list of parallel tracks within the field's boundary
-- At this point, tracks are defined only by they endpoints and 
-- are not connected
function generateParallelTracks( polygon, width )
  local tracks = {}
  local trackIndex = 1
  for y = polygon.boundingBox.minY + width / 2, polygon.boundingBox.maxY, width do
    local from = { x = polygon.boundingBox.minX, y = y, track=trackIndex }
    local to = { x = polygon.boundingBox.maxX, y = y, track=trackIndex }
    -- for now, all tracks go from min to max, we'll take care of
    -- alternating directions later.
    table.insert( tracks, { from=from, to=to, intersections={}} )
    trackIndex = trackIndex + 1
  end
  -- tracks has now a list of segments covering the bounding box of the 
  -- field. 
  findIntersections( polygon, tracks )
  return tracks
end

--- Input is a field boundary (like the innermost headland track) and 
--  a list of segments. The segments represent the parallel tracks. 
--  This function finds the intersections with the the field
--  boundary.
function findIntersections( polygon, tracks )
  local ix = function( a ) return getPolygonIndex( polygon, a ) end
  polygon.bottomIntersections = {}
  polygon.topIntersections = {}
  -- loop through the polygon and check each vector from 
  -- the current point to the next
  for i, cp in ipairs( polygon ) do
    local np = polygon[ ix( i + 1 )] 
    for j, t in ipairs( tracks ) do
      local is = getIntersection( cp.x, cp.y, np.x, np.y, t.from.x, t.from.y, t.to.x, t.to.y ) 
      if is then
        -- the line between from and to (the track) intersects the vector from cp to np
        -- remember the polygon vertex where we are intersecting
        is.index = i
        addPointToListOrderedByX( t.intersections, is )
        -- Remember the intersections with the first and the last track. 
        -- This is were we will want to transition from the headland to the center
        -- parallel tracks
        if j == 1 then
          -- bottommost track
          table.insert( polygon.bottomIntersections, { index=i, point=is })
        end
        if j == #tracks then
          -- topmost track
          table.insert( polygon.topIntersections, { index=i, point=is })
        end
      end
    end
  end
end

--- convert a list of tracks to waypoints, also cutting off
-- the part of the track which is outside of the field.
--
-- use the fact that at this point the field and the tracks
-- are rotated so that the tracks are parallel to the x axle and 
-- the first track has the lowest y coordinate
--
-- Also, we expect the tracks already have the intersection points with
-- the field boundary and there are exactly two intersection points
function addWaypointsToTracks( tracks, width, extendTracks )
  local result = {}
  for i = 1, #tracks do
    if #tracks[ i ].intersections > 1 then
      local newFrom = math.min( tracks[ i ].intersections[ 1 ].x, tracks[ i ].intersections[ 2 ].x ) + width / 2 - extendTracks
      local newTo = math.max( tracks[ i ].intersections[ 1 ].x, tracks[ i ].intersections[ 2 ].x ) - width / 2 + extendTracks
      -- if a track is very short (shorter than width) we may end up with newTo being
      -- less than newFrom. Just skip that track
      if newTo > newFrom then
        tracks[ i ].waypoints = {}
        for x = newFrom, newTo, waypointDistance do
          table.insert( tracks[ i ].waypoints, { x=x, y=tracks[ i ].from.y, track=i })
        end
        -- make sure we actually reached newTo, if waypointDistance is too big we may end up 
        -- well before the innermost headland track or field boundary
        if newTo - tracks[ i ].waypoints[ #tracks[ i ].waypoints ].x > waypointDistance * 0.25 then
          table.insert( tracks[ i ].waypoints, { x=newTo, y=tracks[ i ].from.y, track=i })
        end
      end
    end
    -- return only tracks with waypoints
    if tracks[ i ].waypoints then
      table.insert( result, tracks[ i ])
    end
  end
  return result
end 

--- Start walking on the headland at the given point until
-- we bump onto a corner of an unworked block. 
-- returns the to/from index in headland where the work for this 
-- block ends, that is, where we should start looking for the next block 
function findTrackToNextBlock( blocks, headland, from, to, step )
  local track = {}
  local ix
  for i in polygonIterator( headland, from, to, step ) do
    table.insert( track, headland[ i ])
    for j, b in ipairs( blocks ) do
      if not b.covered then
        if i == b.bottomLeftIntersection.index then
          print( string.format( "Starting block %d at bottom left", j ))
          b.bottomToTop, b.leftToRight = true, true
          b.covered = true
          b.trackToThisBlock = track
          -- where we end working the block depends on the number of track
          -- TODO: works only for alternating tracks as long as no track
          -- skipped.
          if #b % 2 == 0 then 
            ix = b.topLeftIntersection.index
          else
            ix = b.topRightIntersection.index 
          end
          return ix, getPolygonIndex( headland, ix - step ), b
        elseif i == b.bottomRightIntersection.index then
          print( string.format( "Starting block %d at bottom right", j ))
          b.bottomToTop, b.leftToRight = true, false
          b.covered = true
          b.trackToThisBlock = track
          if #b % 2 == 0 then 
            ix = b.topRightIntersection.index
          else
            ix = b.topLeftIntersection.index 
          end
          return ix, getPolygonIndex( headland, ix - step ), b
        elseif i == b.topLeftIntersection.index then 
          print( string.format( "Starting block %d at top left", j ))
          b.bottomToTop, b.leftToRight = false, true
          b.covered = true
          b.trackToThisBlock = track
          if #b % 2 == 0 then 
            ix = b.bottomLeftIntersection.index
          else
            ix = b.bottomRightIntersection.index 
          end
          return ix, getPolygonIndex( headland, ix - step ), b
        elseif i == b.topRightIntersection.index then
          print( string.format( "Starting block %d at top right", j ))
          b.bottomToTop, b.leftToRight = false, false
          b.covered = true
          b.trackToThisBlock = track
          if #b % 2 == 0 then 
            ix = b.bottomRightIntersection.index
          else
            ix = b.bottomLeftIntersection.index 
          end
          return ix, getPolygonIndex( headland, ix - step ), b
        end
      end
    end
  end
  return nil, nil, nil
end

--- Find the 'corner' closest to the end of the last headland pass.
-- The vehicle then will move on the last headland track until it
-- reaches this corner and starts working on the parallel tracks in 
-- the middle of the field.
function findStartOfParallelTracks( field, from, to, step )
  -- field.toIndex is the last point of the headland path
  -- the point with the smallest x is on the left
  local bottomLeftIx, bottomRightIx, topLeftIx, topRightIx
  if field.bottomIntersections[ 2 ].point.x >= field.bottomIntersections[ 1 ].point.x then
    bottomLeftIx = field.bottomIntersections[ 1 ].index
    bottomRightIx = field.bottomIntersections[ 2 ].index
  else
    bottomLeftIx = field.bottomIntersections[ 2 ].index
    bottomRightIx = field.bottomIntersections[ 1 ].index
  end
  if field.topIntersections[ 2 ].point.x >= field.topIntersections[ 1 ].point.x then
    topLeftIx = field.topIntersections[ 1 ].index
    topRightIx = field.topIntersections[ 2 ].index
  else
    topLeftIx = field.topIntersections[ 2 ].index
    topRightIx = field.topIntersections[ 1 ].index
  end
  local track = {}
  for i in polygonIterator( field, from, to, step ) do
    table.insert( track, field[ i ])
    if i == bottomLeftIx then
      print( "Starting at bottom left" )
      return true, true, track
    elseif i == bottomRightIx then
      print( "Starting at bottom right" )
      return true, false, track
    elseif i == topLeftIx then 
      print( "Starting at top left" )
      return false, true, track
    elseif i == topRightIx then
      print( "Starting at top right" )
      return false, false, track
    end
  end
  print( "Start not found, starting at bottom left" )
  io.stdout:flush()
  return true, true, track
end

--- Link the parallel tracks in the center of the field to one 
-- continuous track.
-- if bottomToTop == true then start at the bottom and work our way up
-- if leftToRight == true then start the first track on the left 
-- nTracksToSkip - number of tracks to skip when doing alternative 
-- tracks
function linkParallelTracks( result, parallelTracks, bottomToTop, leftToRight, nTracksToSkip ) 
  if not bottomToTop then
    -- we start at the top, so reverse order of tracks as after the generation, 
    -- the last one is on the top
    parallelTracks = reverseTracks( parallelTracks )
  end
  parallelTracks = reorderTracksForAlternateFieldwork( parallelTracks, nTracksToSkip )
  
  -- now make sure that the we work on the tracks in alternating directions
  -- we generate track from left to right, so the ones which we'll traverse
  -- in the other direction must be reversed.
  local start
  if leftToRight then
    -- starting on the left, the first track is not reversed
    start = 2 
  else
    start = 1
  end
  -- reverse every second track
  for i = start, #parallelTracks, 2 do
    parallelTracks[ i ].waypoints = reverse( parallelTracks[ i ].waypoints)
  end
  local startTrack = 1
  local endTrack = #parallelTracks
  local trackStep = 1
  for i = startTrack, endTrack, trackStep do
    if parallelTracks[ i ].waypoints then
      for j, point in ipairs( parallelTracks[ i ].waypoints) do
        -- the first point of a track is the end of the turn (except for the first track)
        if ( j == 1 and i ~= startTrack ) then 
          point.turnEnd = true
        end
        -- the last point of a track is the start of the turn (except for the last track)
        if ( j == #parallelTracks[ i ].waypoints and i ~= endTrack ) then
          point.turnStart = true
        end
        table.insert( result, point )
      end      
    else
      print( string.format( "Track %d has no waypoints, skipping.", i ))
    end
  end
end

--- Check parallel tracks to see if the turn start and turn end waypoints
-- are too far away. If this is the case, add waypoints
-- Assume this is called at the first waypoint of a new track (turnEnd == true)
--
-- This may help the auto turn algorithm, sometimes it can't handle turns 
-- when turnstart and turnend are too far apart
--
function addWaypointsForTurnsWhenNeeded( track )
  local result = {}
  for i, point in ipairs( track ) do
    if point.turnEnd then
      local distanceFromTurnStart = getDistanceBetweenPoints( point, track[ i - 1 ])
      if distanceFromTurnStart > waypointDistance * 2 then
        -- too far, add a waypoint between the start of the current track and 
        -- the end of the previous one.
        print( "adding a point at ", i )
        local x, y = getPointInTheMiddle( point, track[ i - 1])
        -- also, we are moving the turn end to this new point
        track[ i - 1 ].turnStart = nil
        table.insert( result, { x=x, y=y, turnStart=true })
      end
    end
    table.insert( result, point )
  end
  print( "track had " .. #track .. ", result has " .. #result )
  return result
end

--- count tracks based on their intersection with a field boundary
-- if there are two intersections, it is one track
-- if there are more than two, it is actually two or more tracks because of a concave field 
function countTracks( tracks )
  local nFullTracks = 0
  -- tracks intersecting a concave field boundary
  local nSplitTracks = 0 
  for j, t in ipairs( tracks ) do
    if #t.intersections > 2 then 
      nSplitTracks = nSplitTracks + ( #t.intersections - 2 ) / 2
    else
      nFullTracks = nFullTracks + 1
    end
  end
  return nFullTracks, nSplitTracks
end

function reverseTracks( tracks )
  local reversedTracks = {}
  for i = #tracks, 1, -1 do
    table.insert( reversedTracks, tracks[ i ])
  end
  return reversedTracks
end

--- Reorder parallel tracks for alternating track fieldwork.
-- This allows for example for working on every odd track first 
-- and then on the even ones so turns at track ends can be wider.
--
-- For example, if we have five tracks: 1, 2, 3, 4, 5, and we 
-- want to skip every second track, we'd work in the following 
-- order: 1, 3, 5, 4, 2
--
function reorderTracksForAlternateFieldwork( parallelTracks, nTracksToSkip )
  -- start with the first track and work up to the last,
  -- skipping every nTrackToSkip tracks.
  local reorderedTracks = {}
  local workedTracks = {}
  local lastWorkedTrack
  -- need to work on this until all tracks are covered
  while ( #reorderedTracks < #parallelTracks ) do
    -- find first non-worked track
    local start = 1
    while workedTracks[ start ] do start = start + 1 end
    for i = start, #parallelTracks, nTracksToSkip + 1 do
      table.insert( reorderedTracks, parallelTracks[ i ])
      workedTracks[ i ] = true
      lastWorkedTrack = i
    end
    -- we reached the last track, now turn back and work on the 
    -- rest, find the last unworked track first
    for i = lastWorkedTrack + 1, 1, - ( nTracksToSkip + 1 ) do
      if ( i <= #parallelTracks ) and not workedTracks[ i ] then
        table.insert( reorderedTracks, parallelTracks[ i ])
        workedTracks[ i ] = true
      end
    end
  end
  return reorderedTracks
end

--- Find blocks of center tracks which have to be worked separately
-- in case of non-convex fields or islands
--
-- These blocks consist of tracks and each of these tracks will have
-- exactly two intersection points with the headland
--
function splitCenterIntoBlocks( tracks, blocks )
  local block = {}
  local previousTrack = nil
  for i, t in ipairs( tracks ) do
    -- start at the bottommost track
    -- as long as there are only 2 intersections with the field boundary, we
    -- are ok as this is a convex area
    if #t.intersections >= 2 then
      -- add this track to the new block
      -- but move the leftmost two intersections of the original track to this block
      -- first find the two leftmost intersections (min x), which are ix 1 and 2 as 
      -- the list of intersections is ordered by x
      local newTrack = { from=t.from, to=t.to, intersections={ copyPoint( t.intersections[ 1 ]), copyPoint( t.intersections[ 2 ])}}
      -- continue with this block only if the tracks overlap, otherwise we are done with this
      -- block. Don't check first track obviously
      if previousTrack and not overlaps( newTrack, previousTrack ) then
        break
      end
      previousTrack = newTrack
      table.insert( block, newTrack )
      table.remove( t.intersections, 1 )
      table.remove( t.intersections, 1 )
    end
    if #t.intersections > 0 and ( #t.intersections % 2  ) == 1 then
      print( string.format( "**** Track %d has %d intersections!", i, #t.intersections ))
    end
    io.stdout:flush()
  end
  if #block == 0 then
    -- no tracks could be added to the block, we are done
    return blocks
  else
    -- block has new tracks, add it to the list and continue splitting
    -- for our convenience, remember the corners
    block.bottomLeftIntersection = block[ 1 ].intersections[ 1 ]
    block.bottomRightIntersection = block[ 1 ].intersections[ 2 ]
    block.topLeftIntersection = block[ #block ].intersections[ 1 ]
    block.topRightIntersection = block[ #block ].intersections[ 2 ]
    table.insert( blocks, block )
    return splitCenterIntoBlocks( tracks, blocks )
  end
end

--- add a point to a list of intersections but make sure the 
-- list is ordered from left to right, that is, the first element has 
-- the smallest x, the last the greatest x
function addPointToListOrderedByX( is, point )
  local i = #is
  while i > 0 and point.x < is[ i ].x do 
    i = i - 1
  end
  table.insert( is, i + 1, point )
end

--- check if two tracks overlap. We assume tracks are horizontal
-- and therefore check only the x coordinate
-- also, we assume that both track's endpoints are defined in the
-- intersections list and there are only two intersections.
function overlaps( t1, t2 )
  local t1x1, t1x2 = t1.intersections[ 1 ].x, t1.intersections[ 2 ].x
  local t2x1, t2x2 = t2.intersections[ 1 ].x, t2.intersections[ 2 ].x
  if t1x2 < t2x1 or t2x2 < t1x1 then 
    return false
  else
    return true
  end
end
