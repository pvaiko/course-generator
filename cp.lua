--- This is the interface to Courseplay
-- 

local p = g_currentModDirectory .. '/course-generator/'

dofile( p .. 'track.lua' )
dofile( p .. 'file.lua' )
dofile( p .. 'headland.lua' )
dofile( p .. 'center.lua' )
dofile( p .. 'geo.lua' )
dofile( p .. 'bspline.lua' )


function generate( vehicle, name, poly )

  DebugUtil.printTableRecursively( vehicle.components, "  ", 1, 6 )

  local field = fromCpField( name, poly.points ) 
  calculatePolygonData( field.boundary )

  field.vehicle = { location = {x=vehicle.components[ 1 ].sentTranslation[ 1 ], y=vehicle.components[ 1 ].sentTranslation[ 3 ]}, heading = 180 }

  field.width = 6
  field.nHeadlandPasses = 3
  field.headlandClockwise = true
  field.overlap = 0
  field.nTracksToSkip = 0
  field.extendTracks = 0
  field.minDistanceBetweenPoints = 0.5
  field.angleThresholdDeg = 30
  field.doSmooth = true
  field.roundCorners = true

  DebugUtil.printTableRecursively( field, "  ", 1, 6 )
  generateCourseForField( field, field.width, field.nHeadlandPasses, 
                          field.headlandClockwise, field.vehicle.location,
                          field.overlap, field.nTracksToSkip,
                          field.extendTracks, field.minDistanceBetweenPoints,
                          math.rad( field.angleThresholdDeg ), field.doSmooth,
                          field.roundCorners
                        )

  DebugUtil.printTableRecursively( field, "  ", 1, 2 )
  writeCourseToFile( field, "kakukk" )
end

