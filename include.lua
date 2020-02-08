local courseGeneratorPath = 'courseplay/course-generator/'
dofile('courseplay/CpObject.lua')
dofile( courseGeneratorPath .. 'geo.lua' )
dofile( courseGeneratorPath .. 'Island.lua' )
dofile( courseGeneratorPath .. 'Genetic.lua' )
dofile( courseGeneratorPath .. 'Pathfinder.lua' )
dofile( courseGeneratorPath .. 'courseGenerator.lua' )
dofile( courseGeneratorPath .. 'track.lua' )
dofile( courseGeneratorPath .. 'headland.lua' )
dofile( courseGeneratorPath .. 'center.lua' )
dofile('courseplay/course-generator/BinaryHeap.lua')
dofile('courseplay/course-generator/Vector.lua')
dofile('courseplay/course-generator/State3D.lua')
dofile('courseplay/course-generator/HybridAStar.lua')
dofile('courseplay/course-generator/PathfinderUtil.lua')
dofile('courseplay/course-generator/Dubins.lua')
dofile('courseplay/course-generator/ReedsShepp.lua')
dofile('courseplay/course-generator/ReedsSheppSolver.lua')
dofile('courseplay/course-generator/Dijkstra.lua')
dofile('courseplay/Waypoint.lua')

dofile( 'Vehicle.lua' )
dofile( 'file.lua' )

-- TODO: fix this dependency
courseplay = {}
courseplay.RIDGEMARKER_NONE = 0
courseplay.RIDGEMARKER_LEFT = 1
courseplay.RIDGEMARKER_RIGHT = 2