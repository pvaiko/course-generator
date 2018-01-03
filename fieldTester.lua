dofile( 'include.lua' )

marks = {}

function printParameters()
  print( "implementWidth = ", implementWidth )
  print( "nHeadlandPasses = ", nHeadlandPasses )
  print( "headlandClockwise = ", tostring( headlandClockwise ))
  print( "headlandStartLocation = ", headlandStartLocation.x, headlandStartLocation.y )
  print( "overlapPercent = ", overlapPercent )
  print( "nTracksToSkip = ", nTracksToSkip )
  print( "extendTracks = ", extendTracks )
  print( "minDistanceBetweenPoints = ", minDistanceBetweenPoints )
  print( "minSmoothAngleDeg = ", minSmoothAngleDeg )
  print( "maxSmoothAngleDeg =", maxSmoothAngleDeg )
  print( "doSmooth = ", tostring( doSmooth ))
  print( "fromInside = ", tostring( fromInside ))
  print( "turnRadius = ", turnRadius )
  print( "minHeadlandTurnAngleDeg =", minHeadlandTurnAngleDeg )
  print( "#idlandNodes = ", field.islandNodes and #field.islandNodes or 0 )
  print( "headlandFirst = ", tostring( headlandFirst ))
end

function generate()
 local status, err = xpcall( generateCourseForField, function() print( err, debug.traceback()) printParameters() end,
                             field, implementWidth, nHeadlandPasses, headlandClockwise, 
                             headlandStartLocation, overlapPercent, 
                             nTracksToSkip, extendTracks,
                             minDistanceBetweenPoints, math.rad( minSmoothAngleDeg ), math.rad( maxSmoothAngleDeg ), doSmooth, fromInside,
                             turnRadius, math.rad( minHeadlandTurnAngleDeg ), returnToFirst, field.islandNodes, headlandFirst )
  end

function generateFromAllCorners()
  generate()
  headlandStartLocation = { x = bb.maxX, y = bb.minY }
  generate()
  headlandStartLocation = { x = bb.maxX, y = bb.maxY }
  generate()
  headlandStartLocation = { x = bb.minX, y = bb.maxY }
  generate()
end

function courseGenerator.debug2( text )
  -- disable debug outputs
end

function resetParameter()
  implementWidth = 6
  nHeadlandPasses = 4
  headlandClockwise = true
  headlandStartLocation = {}
  overlapPercent = 0
  nTracksToSkip = 0
  extendTracks = 0
  minDistanceBetweenPoints = 0.5
  minSmoothAngleDeg = 30
  maxSmoothAngleDeg = 60
  doSmooth = true
  fromInside = false
  turnRadius = 6
  minHeadlandTurnAngleDeg = 60
  returnToFirst = true
  islandNodes = {}
  headlandFirst = true
end

-----------------------------------------------------------------------------
resetParameter()
fieldFile = "fields/coldborough.xml"
savedFields = loadSavedFields( fieldFile )

fieldNumber = 7
field = savedFields[ fieldNumber ]
print( "#####################################################################" )
print( string.format( "Testing field %d from %s", fieldNumber, fieldFile ))
field.boundary = Polygon:new( field.boundary )
bb =  field.boundary:getBoundingBox()
headlandStartLocation = { x = bb.minX, y = bb.minY }
nHeadlandPasses = 20; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 12 )

nHeadlandPasses = 0; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 0 )

nHeadlandPasses = 4; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 4 )

headlandClockwise = false; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 4 )

headlandFirst = false; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 4 )

-----------------------------------------------------------------------------
resetParameter()
fieldFile = "fields/coldborough.xml"
savedFields = loadSavedFields( fieldFile )

fieldNumber = 9
field = savedFields[ fieldNumber ]
field.boundary = Polygon:new( field.boundary )
print( "#####################################################################" )
print( string.format( "Testing field %d from %s", fieldNumber, fieldFile ))

bb =  field.boundary:getBoundingBox()
headlandStartLocation = { x = bb.minX, y = bb.minY }
nHeadlandPasses = 3; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 3 )
--
-----------------------------------------------------------------------------
resetParameter()
fieldFile = "fields/Goldcrest.xml"
savedFields = loadSavedFields( fieldFile )

fieldNumber = 24
field = savedFields[ fieldNumber ]
field.boundary = Polygon:new( field.boundary )
print( "#####################################################################" )
print( string.format( "Testing field %d from %s", fieldNumber, fieldFile ))

bb =  field.boundary:getBoundingBox()
headlandStartLocation = { x = bb.minX, y = bb.minY }
implementWidth = 3.5
nHeadlandPasses = 0; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 0 )

nHeadlandPasses = 4; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 4 )

nHeadlandPasses = 12; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 11 )

nHeadlandPasses = 4; fromInside = true; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 4 )

-----------------------------------------------------------------------------
resetParameter()
fieldFile = "fields/FlusstalXXL.xml"
savedFields = loadSavedFields( fieldFile )

fieldNumber = 59
field = savedFields[ fieldNumber ]
field.boundary = Polygon:new( field.boundary )
print( "#####################################################################" )
print( string.format( "Testing field %d from %s", fieldNumber, fieldFile ))

bb =  field.boundary:getBoundingBox()
headlandStartLocation = { x = bb.minX, y = bb.minY }
nHeadlandPasses = 4; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 4 )

nHeadlandPasses = 0; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 0 )

nHeadlandPasses = 200; generate()
assert( #field.course > 100 )
assert( #field.headlandTracks == 44 )


