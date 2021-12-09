if love == nil then
	package.cpath = package.cpath .. ';C:/Users/nyovape1/AppData/Local/JetBrains/Toolbox/apps/IDEA-U/ch-0/212.5457.46.plugins/EmmyLua/classes/debugger/emmy/windows/x86/?.dll'
	local dbg = require('emmy_core')
	dbg.tcpConnect('localhost', 9966)
end

dofile('../courseplay/scripts/CpObject.lua')

dofile('../test/mock-Courseplay.lua')
dofile('../test/mock-GiantsEngine.lua')
dofile('../test/MockNode.lua')
dofile('../test/TurnTestHelper.lua')

dofile('../courseplay/scripts/CpUtil.lua')
dofile('../courseplay/scripts/Waypoint.lua')
dofile('../courseplay/scripts/ai/AIUtil.lua' )
dofile('../courseplay/scripts/ai/CpMathUtil.lua' )
dofile('../courseplay/scripts/ai/turns/TurnContext.lua' )
dofile('../courseplay/scripts/ai/turns/Corner.lua' )
dofile('../courseplay/scripts/ai/turns/TurnManeuver.lua' )
dofile('../courseplay/scripts/courseGenerator/geo.lua' )
dofile('../courseplay/scripts/courseGenerator/CourseGenerator.lua' )
dofile('../courseplay/scripts/courseGenerator/Vector.lua' )
dofile('../courseplay/scripts/pathfinder/AnalyticSolution.lua')
dofile('../courseplay/scripts/pathfinder/State3D.lua')

local workWidth = 4
local vehicle = TurnTestHelper.createVehicle('test vehicle')
local course, turnStartIx = TurnTestHelper.createCornerCourse(vehicle)
local turnContext = TurnTestHelper.createTurnContext(course, turnStartIx, workWidth)
local tm = TurnTestHelper.createHeadlandCornerTurnManeuver(vehicle, turnContext, 0, 0, workWidth)
tm:getCourse():print()