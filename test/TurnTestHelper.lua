TurnTestHelper = {}

function TurnTestHelper.createVehicle(name)
	local vehicle = {
		getName = function () return name end,
	}
	return vehicle
end

-- create a course with 90 corner
function TurnTestHelper.createCornerCourse(vehicle, startX, startZ)
	local course = Course.createFromTwoWorldPositions(vehicle, startX, startZ, startX + 20, startZ, 0, 0, 0, 5, false)
	local lastWp = table.remove(course.waypoints)
	local turnStartIx = course:getNumberOfWaypoints()
	course.waypoints[#course.waypoints].turnStart = true
	local courseAfterTurn = Course.createFromTwoWorldPositions(vehicle, lastWp.x, lastWp.z, lastWp.x, startZ + 20, 0, 0, 0, 5, false)
		-- remove first point as it would be the same as the last point of course
	courseAfterTurn.waypoints[1].turnEnd = true
	course:append(courseAfterTurn)
	course:enrichWaypointData()
	return course, turnStartIx
end

-- create a course with 180 turn
function TurnTestHelper.create180Course(vehicle, startX, startZ, workWidth, length, zOffset)
	local course = Course.createFromTwoWorldPositions(vehicle, startX, startZ, startX + length, startZ, 0, 0, 0, 5, false)
	local turnStartIx = course:getNumberOfWaypoints()
	course.waypoints[#course.waypoints].turnStart = true
	local courseAfterTurn = Course.createFromTwoWorldPositions(vehicle, startX + length + zOffset, startZ + workWidth, startX, startZ + workWidth, 0, 0, 0, 5, false)
	-- remove first point as it would be the same as the last point of course
	courseAfterTurn.waypoints[1].turnEnd = true
	course:append(courseAfterTurn)
	course:enrichWaypointData()
	return course, turnStartIx
end


function TurnTestHelper.createTurnContext(course, turnStartIx, workWidth, frontMarkerDistance, backMarkerDistance)
	local turnNodes = {}
	local turnEndSideOffset, turnEndForwardOffset = 0, 0

	return TurnContext(course, turnStartIx, turnStartIx + 1, turnNodes, workWidth,
		frontMarkerDistance, backMarkerDistance, turnEndSideOffset, turnEndForwardOffset)
end


function TurnTestHelper.createHeadlandCornerTurnManeuver(vehicle, turnContext, vx, vz, workWidth, steeringLength)

	local vehicleDirectionNode = CpUtil.createNode('vehicleDirectionNode', vx, vz, 0)
	local turningRadius = 6

	return HeadlandCornerTurnManeuver(vehicle, turnContext, turnContext.vehicleAtTurnStartNode, turningRadius, workWidth, steeringLength > 0, steeringLength)
end
