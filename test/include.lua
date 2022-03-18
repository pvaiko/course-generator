local courseGeneratorPath = 'courseplay/scripts/courseGenerator/'
-- TODO: fix this dependency
courseplay = {}
courseplay.RIDGEMARKER_NONE = 0
courseplay.RIDGEMARKER_LEFT = 1
courseplay.RIDGEMARKER_RIGHT = 2

dofile('courseplay/scripts/CpObject.lua')
dofile('courseplay/scripts/courseGenerator/geo.lua' )
dofile('courseplay/scripts/courseGenerator/Island.lua' )
dofile('courseplay/scripts/courseGenerator/Genetic.lua' )
dofile('courseplay/scripts/courseGenerator/track.lua' )
dofile('courseplay/scripts/courseGenerator/CourseGenerator.lua' )
dofile('courseplay/scripts/courseGenerator/headland.lua' )
dofile('courseplay/scripts/courseGenerator/center.lua' )
dofile('courseplay/scripts/courseGenerator/Vector.lua' )
dofile('courseplay/scripts/pathfinder/ReedsShepp.lua')
dofile('courseplay/scripts/pathfinder/ReedsSheppSolver.lua')
dofile('courseplay/scripts/pathfinder/Dubins.lua' )
dofile('courseplay/scripts/pathfinder/PathfinderUtil.lua' )
dofile('courseplay/scripts/pathfinder/BinaryHeap.lua')
dofile('courseplay/scripts/pathfinder/State3D.lua')
dofile('courseplay/scripts/pathfinder/HybridAStar.lua')
dofile('courseplay/scripts/pathfinder/Dijkstra.lua')
dofile('test/mock-GiantsEngine.lua')
dofile('test/mock-Courseplay.lua')
--dofile('test/TestPathfinderConstraints.lua')
--PathfinderConstraints = TestPathfinderConstraints
--dofile(courseGeneratorPath .. 'JumpPoint.lua')
--dofile(courseGeneratorPath .. 'Rrt.lua')
dofile('courseplay/scripts/Waypoint.lua')
dofile('courseplay/scripts/Course.lua')
--dofile('courseplay/settings.lua')
--dofile(courseGeneratorPath .. 'CourseGeneratorSettings.lua')

