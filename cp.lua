--- This is the interface to Courseplay
-- 

local p = g_currentModDirectory .. '/course-generator/'

dofile( p .. 'track.lua' )
dofile( p .. 'file.lua' )
dofile( p .. 'headland.lua' )
dofile( p .. 'center.lua' )
dofile( p .. 'geo.lua' )
dofile( p .. 'bspline.lua' )


function generate( vehicle, poly )

  DebugUtil.printTableRecursively( vehicle.components, "  ", 1, 6 )
  DebugUtil.printTableRecursively( poly, "  ", 1, 6 )

end

