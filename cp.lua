--- This is the interface to Courseplay
-- 

function generate( vehicle, name, poly )

  local field = fromCpField( name, poly.points ) 
  calculatePolygonData( field.boundary )

  local location = {x=vehicle.components[ 1 ].sentTranslation[ 1 ], y=-vehicle.components[ 1 ].sentTranslation[ 3 ]}

  field.width = vehicle.cp.workWidth 
  field.headlandClockwise = vehicle.cp.userDirClockwise
  field.overlap = 0
  field.nTracksToSkip = 0
  field.extendTracks = 0
  field.minDistanceBetweenPoints = 0.5
  field.angleThresholdDeg = 30
  field.doSmooth = true
  field.roundCorners = false

  generateCourseForField( field, vehicle.cp.workWidth, vehicle.cp.headland.numLanes,
                          vehicle.cp.headland.userDirClockwise, location,
                          field.overlap, field.nTracksToSkip,
                          field.extendTracks, field.minDistanceBetweenPoints,
                          math.rad( field.angleThresholdDeg ), field.doSmooth,
                          field.roundCorners
                        )
 
  if not vehicle.cp.headland.orderBefore then
    field.course = reverseCourse( field.course )
  end

  writeCourseToVehicleWaypoints( vehicle, field.course )

	vehicle.cp.numWaypoints = #vehicle.Waypoints	
	
	if vehicle.cp.numWaypoints == 0 then
		courseplay:debug('ERROR: #vehicle.Waypoints == 0 -> cancel and return', 7);
		return;
	end;

	courseplay:setWaypointIndex(vehicle, 1);
	vehicle:setCpVar('canDrive',true,courseplay.isClient);
	vehicle.Waypoints[1].wait = true;
	vehicle.Waypoints[1].crossing = true;
	vehicle.Waypoints[vehicle.cp.numWaypoints].wait = true;
	vehicle.Waypoints[vehicle.cp.numWaypoints].crossing = true;
	vehicle.cp.numCourses = 1;
	courseplay.signs:updateWaypointSigns(vehicle);

	-- extra data for turn maneuver
	vehicle.cp.courseWorkWidth = vehicle.cp.workWidth;
	vehicle.cp.courseNumHeadlandLanes = numHeadlandLanesCreated;
	vehicle.cp.courseHeadlandDirectionCW = vehicle.cp.headland.userDirClockwise;

	vehicle.cp.hasGeneratedCourse = true;
	courseplay:setFieldEdgePath(vehicle, nil, 0);
	courseplay:validateCourseGenerationData(vehicle);
	courseplay:validateCanSwitchMode(vehicle);

	-- SETUP 2D COURSE DRAW DATA
	vehicle.cp.course2dUpdateDrawData = true;

end

--- Convert the generated course to CP waypoint format
--
function writeCourseToVehicleWaypoints( vehicle, course )
	vehicle.Waypoints = {};

  for i, point in ipairs( course ) do
    local wp = {}

    wp.generated = true
    wp.ridgeMarker = 0
    wp.angle = toCpAngle( point.nextEdge.angle )
    wp.cx = point.x
    wp.cz = -point.y
    wp.wait = nil
    wp.rev = nil
    wp.crossing = nil

    if point.passNumber then
      wp.lane = -point.passNumber
    end
    if point.turnStart then
      wp.turnStart = true
    end
    if point.turnEnd then
      wp.turnEnd = true
    end
    table.insert( vehicle.Waypoints, wp )
  end
end

--- Return true when running in the game
-- used by file and log functions to determine how exactly to do things,
-- for example, io.flush is not available from within the game.
--
function isRunningInGame()
  return g_currentModDirectory ~= nil;
end
