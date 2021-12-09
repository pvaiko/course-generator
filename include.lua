local courseGeneratorPath = 'courseplay/scripts/courseGenerator/'
-- TODO: fix this dependency
courseplay = {}
courseplay.RIDGEMARKER_NONE = 0
courseplay.RIDGEMARKER_LEFT = 1
courseplay.RIDGEMARKER_RIGHT = 2


dofile('courseplay/scripts/CpObject.lua')
dofile('courseplay/scripts/CpUtil.lua')
dofile( courseGeneratorPath .. 'geo.lua' )
dofile( courseGeneratorPath .. 'Island.lua' )
dofile( courseGeneratorPath .. 'Genetic.lua' )
dofile( courseGeneratorPath .. 'CourseGenerator.lua' )
dofile( courseGeneratorPath .. 'track.lua' )
dofile( courseGeneratorPath .. 'headland.lua' )
dofile( courseGeneratorPath .. 'center.lua' )
dofile('test/MockNode.lua')
dofile('test/mock-GiantsEngine.lua')
dofile('test/mock-Courseplay.lua')

dofile('courseplay/scripts/Waypoint.lua')
dofile('courseplay/scripts/courseGenerator/Vector.lua')
--dofile('courseplay/scripts/courseGenerator/BinaryHeap.lua')
--dofile('courseplay/scripts/courseGenerator/State3D.lua')
--dofile('courseplay/scripts/courseGenerator/HybridAStar.lua')
--dofile('courseplay/scripts/courseGenerator/Dubins.lua')
--dofile('courseplay/scripts/courseGenerator/ReedsShepp.lua')
--dofile('courseplay/scripts/courseGenerator/ReedsSheppSolver.lua')
--dofile('courseplay/scripts/courseGenerator/Dijkstra.lua')
--dofile('courseplay/scripts/courseGenerator/PathfinderUtil.lua')
--dofile('courseplay/settings.lua')
--dofile('courseplay/scripts/courseGenerator/CourseGeneratorSettings.lua')

dofile( 'Vehicle.lua' )
dofile( 'file.lua' )
