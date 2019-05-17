dofile( 'include.lua' )

marks = {}

local headlandSettings = {}
local implementWidth = 6
local extendTracks = 0
local minDistanceBetweenPoints = 0.5
local minSmoothAngleDeg = 30
local maxSmoothAngleDeg = 60
local doSmooth = true
local fromInside = false
local turnRadius = 6
local returnToFirst = true
local islandNodes = {}
local islandBypassMode = Island.BYPASS_MODE_CIRCLE;
local centerSettings = {}
local field, bb

function printParameters()
  print( "implementWidth = ", implementWidth )
  print( "headlandSettings.mode = ", headlandSettings.mode )
  print( "headlandSettings.nPasses = ", headlandSettings.nPasses )
  print( "headlandSettings.isClockwise = ", tostring( headlandSettings.isClockwise ))
  print( "headlandSettings.startLocation = ", headlandSettings.startLocation.x, headlandSettings.startLocation.y )
  print( "headlandSettings.overlapPercent = ", headlandSettings.overlapPercent )
  print( "nRowsToSkip = ", centerSettings.nRowsToSkip )
  print( "extendTracks = ", extendTracks )
  print( "minDistanceBetweenPoints = ", minDistanceBetweenPoints )
  print( "minSmoothAngleDeg = ", minSmoothAngleDeg )
  print( "maxSmoothAngleDeg =", maxSmoothAngleDeg )
  print( "doSmooth = ", tostring( doSmooth ))
  print( "fromInside = ", tostring( fromInside ))
  print( "turnRadius = ", turnRadius )
	print( "returnToFirst = ", tostring( returnToFirst ))
  print( "headlandSettings.minHeadlandTurnAngleDeg =", headlandSettings.minHeadlandTurnAngleDeg )
  print( "#islandNodes = ", field.islandNodes and #field.islandNodes or 0 )
  print( "headlandSettings.headlandFirst = ", tostring( headlandSettings.headlandFirst ))
  print( "islandBypassMode = ", tostring( islandBypassMode ))
end

function assertAndShowSettings( condition, ... )
	if not condition then printParameters() end
	assert(condition, ...)
end

function generate()
 local status, err = xpcall( generateCourseForField, function() print( err, debug.traceback()) printParameters() end,
                             field, implementWidth, headlandSettings, extendTracks,
                             minDistanceBetweenPoints, math.rad( minSmoothAngleDeg ), math.rad( maxSmoothAngleDeg ), doSmooth, fromInside,
                             turnRadius, returnToFirst, field.islandNodes,
                             islandBypassMode, centerSettings )
	if headlandSettings.nPasses < 10 then
		countGlitches(field.course,0)
	else
		-- allow a few glitches with many headlands
		countGlitches(field.course,5)
	end
end

function generatePermutations()
	for i = 0, 1 do
		centerSettings.nRowsToSkip = i
		generate()
		fromInside = true
		generate()
		fromInside = false
		headlandSettings.startLocation = { x = bb.maxX, y = bb.minY }
		generate()
		headlandSettings.startLocation = { x = bb.maxX, y = bb.maxY }
		generate()
		headlandSettings.startLocation = { x = bb.minX, y = bb.maxY }
		generate()
	end
	centerSettings.mode = courseGenerator.CENTER_MODE_CIRCULAR
	generate()
	centerSettings.nRowsToSkip = 0
	centerSettings.mode = courseGenerator.CENTER_MODE_UP_DOWN
end

function countGlitches( course, limit )
	local nGlitches = 0
	for i = 2, #course - 1 do
		local cp, pp, np = course[ i ], course[ i - 1 ], course[ i + 1 ]
		local dA = math.abs( getDeltaAngle( pp.nextEdge.angle, pp.prevEdge.angle ))+
			math.abs( getDeltaAngle( cp.prevEdge.angle, cp.nextEdge.angle ))
		-- the direction changes a lot over two points, this is a glitch
		if dA > math.rad(270) and not pp.reverse then
			nGlitches = nGlitches + 1
			print(string.format("Glitch at wp %d, x=%.1f y=%.1f", i, cp.x, cp.y))
		end
	end
	if nGlitches > limit then
		print( "Glitches found: " .. tostring( nGlitches ) .. " limit was " .. tostring(limit))
		assertAndShowSettings( false )
	end
end


function courseGenerator.debug2( text )
  -- disable debug outputs
end

function resetParameter()
  headlandSettings = {}
	implementWidth = 6
	headlandSettings.mode = courseGenerator.HEADLAND_MODE_NORMAL
	headlandSettings.nPasses = 4
	headlandSettings.isClockwise = true
	headlandSettings.startLocation = {}
  headlandSettings.overlapPercent = 0
	headlandSettings.minHeadlandTurnAngleDeg = 60
	headlandSettings.headlandFirst = true
  extendTracks = 0
  minDistanceBetweenPoints = 0.5
  minSmoothAngleDeg = 30
  maxSmoothAngleDeg = 60
  doSmooth = true
  fromInside = false
  turnRadius = 6
  returnToFirst = true
  islandNodes = {}
  islandBypassMode = Island.BYPASS_MODE_CIRCLE;
  centerSettings = {}
  centerSettings.useBestAngle = true
	centerSettings.nRowsToSkip = 0
end

-----------------------------------------------------------------------------
resetParameter()
local fieldFile = "fields/Felsbrunn.xml"
local savedFields = loadSavedFields( fieldFile )

local fieldNumber = 12
field = savedFields[ fieldNumber ]
print( "#####################################################################" )
print( string.format( "Testing field %d from %s", fieldNumber, fieldFile ))
field.boundary = Polygon:new( field.boundary )
bb =  field.boundary:getBoundingBox()
headlandSettings.startLocation = { x = bb.minX, y = bb.minY }
headlandSettings.mode = courseGenerator.HEADLAND_MODE_TWO_SIDE
headlandSettings.nPasses = 2; generate()
assertAndShowSettings( #field.course > 100 )
headlandSettings.nPasses = 3; generate()
assertAndShowSettings( #field.course > 100 )

fieldNumber = 9
field = savedFields[ fieldNumber ]
print( "#####################################################################" )
print( string.format( "Testing field %d from %s", fieldNumber, fieldFile ))
field.boundary = Polygon:new( field.boundary )
bb =  field.boundary:getBoundingBox()
headlandSettings.startLocation = { x = bb.minX, y = bb.minY }
headlandSettings.mode = courseGenerator.HEADLAND_MODE_TWO_SIDE
headlandSettings.nPasses = 2; generate()
assertAndShowSettings( #field.course > 100 )
headlandSettings.nPasses = 3; generate()
assertAndShowSettings( #field.course > 100 )

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
headlandSettings.startLocation = { x = bb.minX, y = bb.minY }
headlandSettings.nPasses = 20; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 11, "headlandTracks " .. tostring(#field.headlandTracks))

headlandSettings.nPasses = 0; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 0 )

headlandSettings.nPasses = 4; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 4 )
generatePermutations()

headlandSettings.isClockwise = false; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 4 )

headlandSettings.headlandFirst = false; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 4 )

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
headlandSettings.startLocation = { x = bb.minX, y = bb.minY }
headlandSettings.nPasses = 3; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 3 )
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
headlandSettings.startLocation = { x = bb.minX, y = bb.minY }
implementWidth = 3.5
headlandSettings.nPasses = 0; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 0 )

headlandSettings.nPasses = 4; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 4 )
generatePermutations()
headlandSettings.nPasses = 12; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 10 )

headlandSettings.nPasses = 4; fromInside = true; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 4 )


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
headlandSettings.startLocation = { x = bb.minX, y = bb.minY }
headlandSettings.nPasses = 4; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 4 )
generatePermutations()

headlandSettings.nPasses = 0; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 0 )

headlandSettings.nPasses = 200; generate()
assertAndShowSettings( #field.course > 100 )
assertAndShowSettings( #field.headlandTracks == 43 )


