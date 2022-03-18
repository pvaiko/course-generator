-- TODO: fix this dependency
courseplay = {}
courseplay.RIDGEMARKER_NONE = 0
courseplay.RIDGEMARKER_LEFT = 1
courseplay.RIDGEMARKER_RIGHT = 2

local courseplayPath = '../courseplay/'
local testPath = '../test/'

dofile(courseplayPath .. 'scripts/CpObject.lua')
dofile(courseplayPath .. 'scripts/CpUtil.lua')
dofile(courseplayPath .. 'scripts/courseGenerator/geo.lua' )
dofile(courseplayPath .. 'scripts/courseGenerator/Island.lua' )
dofile(courseplayPath .. 'scripts/courseGenerator/Genetic.lua' )
dofile(courseplayPath .. 'scripts/courseGenerator/track.lua' )
dofile(courseplayPath .. 'scripts/courseGenerator/CourseGenerator.lua' )
dofile(courseplayPath .. 'scripts/courseGenerator/headland.lua' )
dofile(courseplayPath .. 'scripts/courseGenerator/center.lua' )
dofile(courseplayPath .. 'scripts/courseGenerator/Vector.lua' )
dofile(courseplayPath .. 'scripts/pathfinder/AnalyticSolution.lua')
dofile(courseplayPath .. 'scripts/pathfinder/ReedsShepp.lua')
dofile(courseplayPath .. 'scripts/pathfinder/ReedsSheppSolver.lua')
dofile(courseplayPath .. 'scripts/pathfinder/Dubins.lua' )
dofile(courseplayPath .. 'scripts/pathfinder/State3D.lua')
dofile(courseplayPath .. 'scripts/pathfinder/PathfinderUtil.lua')
dofile('../courseplay/scripts/util/CpMathUtil.lua' )
dofile('../courseplay/scripts/ai/turns/TurnContext.lua' )
dofile('../courseplay/scripts/ai/turns/Corner.lua' )
dofile('../courseplay/scripts/ai/turns/TurnManeuver.lua' )
dofile(courseplayPath .. 'scripts/Waypoint.lua')
dofile(courseplayPath .. 'scripts/Course.lua')

dofile(testPath .. 'mock-GiantsEngine.lua')
dofile(testPath .. 'mock-Courseplay.lua')
dofile(testPath .. 'MockNode.lua')
dofile(testPath .. 'TurnTestHelper.lua')
dofile(testPath .. 'DebugUtil.lua')
