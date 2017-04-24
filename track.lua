--
-- Functions to manipulate tracks 
--
--

require( 'geo' )
require( 'headland' )
require( 'center' )

--- Generate course for a field.
-- The result will be:
--
-- field.headlandPath 
--   array of points containing all headland passes
--   
-- field.connectingTracks
--   this is the path from the end of the innermost headland track to the start
--   of the parallel tracks in the middle of the field and the connecting tracks
--   between the blocks in the center if the field is non-convex and has been split
--   into blocks
--
-- field.track
--   parallel tracks in the middle of the field.
--
-- field.course
--   all waypoints of the resulting course 
--
-- Input paramters:
--
-- implementWidth 
--   width of the implement
-- 
-- nHeadlandPasses 
--   number of headland passes to generate
--
-- headlandClockwise
--   headland track is clockwise when going inward if true, counterclockwise otherwise
--
-- headlandStartLocation
--   location anywhere near the field boundary where the headland should start.
--
-- overlapPercent 
--   headland pass overlap in percent, may reduce skipped fruit in corners
--
-- nTracksToSkip 
--   center tracks to skip. When 0, normal alternating tracks are generated
--   when > 0, intermediate tracks are skipped to allow for wider turns
--
-- extendTracks
--   extend center tracks into the headland (meters) to prevent unworked
--   triangles with long plows.
--
-- minDistanceBetweenPoints 
--   minimum distance allowed between vertices. Keeps the number of generated
--   vertices for headland passes low. For fine tuning only
--
-- angleThreshold
--   angle between two subsequent edges above which the smoothing kicks in.
--   This is to smooth corners in the headland
--
-- doSmooth
--   enable smoothing 
--
function generateCourseForField( field, implementWidth, nHeadlandPasses, headlandClockwise, 
                                 headlandStartLocation, overlapPercent, 
                                 nTracksToSkip, extendTracks,
                                 minDistanceBetweenPoints, angleThreshold, doSmooth )
  field.boundingBox = getBoundingBox( field.boundary )
  calculatePolygonData( field.boundary )
  field.headlandTracks = {}
  local startHeadlandPass
  print( "Generating innermost headland track" )
  local previousTrack = calculateHeadlandTrack( field.boundary, ( implementWidth - implementWidth * overlapPercent / 100 ) * nHeadlandPasses + implementWidth / 2, 
                                                        minDistanceBetweenPoints, angleThreshold, 0, doSmooth, false ) 
  for j = nHeadlandPasses, 1, -1 do
    local width
    if j == 1 then 
      width = implementWidth / 2
    else 
      width = implementWidth
    end
    print( string.format( "Generating headland track #%d", j ))
    field.headlandTracks[ j ] = calculateHeadlandTrack( previousTrack, width - width * overlapPercent / 100, 
                                                        minDistanceBetweenPoints, angleThreshold, 0, doSmooth, true ) 
    previousTrack = field.headlandTracks[ j ]
  end
  --linkHeadlandTracks( field, implementWidth, headlandClockwise, headlandStartLocation, doSmooth, angleThreshold )
  field.track = generateTracks( field.headlandTracks[ nHeadlandPasses ], implementWidth, nTracksToSkip, extendTracks )
  field.bestAngle = field.headlandTracks[ nHeadlandPasses ].bestAngle
  field.nTracks = field.headlandTracks[ nHeadlandPasses ].nTracks
  -- assemble complete course now
  field.course = {}
  if field.headlandPath then
    for i, point in ipairs( field.headlandPath ) do
      table.insert( field.course, point )
    end
  end
  if field.track then
    for i, point in ipairs( field.track ) do
      table.insert( field.course, point )
    end
  end
  if #field.course > 0 then
    calculatePolygonData( field.course )
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

