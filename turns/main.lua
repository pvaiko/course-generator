--[[

LOVE app to test the Courseplay pathfinding

]]--

dofile( 'include.lua' )

local startHeading = 2 * math.pi / 4
local startPosition = State3D(0, 0, startHeading, 0)
local lastStartPosition = State3D.copy(startPosition)

local goalHeading = 6 * math.pi / 4
local goalPosition = State3D(15, 0, goalHeading, 0)
local lastGoalPosition = State3D.copy(goalPosition)

local vehicle, turnStartIx, turnContext
local workWidth = 6
-- length of the 180 course
local courseLength = 20
local frontMarkerDistance, backMarkerDistance, steeringLength, turningRadius, distanceToFieldEdge = 0, 0, 3, 6, 10

startPosition:setTrailerHeading(startHeading)

local scale, width, height = 30, 500, 400
local origin = {x = -width / 8, y = -height / 4}
local xOffset, yOffset = width / scale / 4 - 20, height / scale + 25

local vehicleData ={name = 'name', turningRadius = turningRadius, dFront = 4, dRear = 2, dLeft = 1.5, dRight = 1.5}
local trailerData ={name = 'name', turningRadius = turningRadius, dFront = 3, dRear = 7, dLeft = 1.5, dRight = 1.5, hitchLength = 10}

local dragging = false
local startTime
local profilerReportLength = 40

local dubinsPath = {}
local rsPath = {}
local rsSolver = ReedsSheppSolver()
local dubinsSolver = DubinsSolver()

local currentHighlight = 1
local currentPathfinderIndex = 1
local done, path, goalNodeInvalid

local line = {}
local courses = {}
local turnContexts = {}
local turnCourses = {}

local function find(start, goal, allowReverse)
    startTime = love.timer.getTime()
    start:setTrailerHeading(start.t)
    local dubinsSolution = dubinsSolver:solve(start, goal, turningRadius)
    dubinsPath = dubinsSolution:getWaypoints(start, turningRadius)
    local rsActionSet = rsSolver:solve(start, goal, turningRadius)
    rsPath = rsActionSet:getWaypoints(start, turningRadius)
    io.stdout:flush()
	lastStartPosition = State3D.copy(startPosition)
	lastGoalPosition = State3D.copy(goalPosition)
    return done, path, goalNodeInvalid
end


local function calculateTurn()
	vehicle = TurnTestHelper.createVehicle('test vehicle')

	local x, z = 0, -20
	courses[1], turnStartIx = TurnTestHelper.createCornerCourse(vehicle, x, z)
	turnContext = TurnTestHelper.createTurnContext(courses[1], turnStartIx, workWidth, frontMarkerDistance, backMarkerDistance)
	turnContexts[1] = turnContext
	turnCourses[1] = HeadlandCornerTurnManeuver(vehicle, turnContext, turnContext.vehicleAtTurnStartNode, turningRadius,
		workWidth, steeringLength > 0, steeringLength):getCourse()
	x, z = 0, 20
	courses[2], turnStartIx = TurnTestHelper.create180Course(vehicle, x, z, workWidth, courseLength)
	turnContext = TurnTestHelper.createTurnContext(courses[2], turnStartIx, workWidth, frontMarkerDistance, backMarkerDistance)
	turnContexts[2] = turnContext
	AIUtil = { getTowBarLength = function () return steeringLength end }
	x, _, z = localToWorld(turnContext.vehicleAtTurnStartNode, 0, 0, 0)
	local x2, _, _ = localToWorld(turnContext.workEndNode, 0, 0, 0)
	-- distanceToFieldEdge is measured from the turn waypoints, not from the vehicle here in the test tool,
	-- therefore, we need to add the distance between the turn end and the vehicle to calculate the distance
	-- in front of the vehicle. This calculation works only in this tool as the 180 turn course is in the x direction...
	turnCourses[2] = DubinsTurnManeuver(vehicle, turnContext, turnContext.vehicleAtTurnStartNode,
		turningRadius, workWidth, steeringLength, distanceToFieldEdge + x2 - x):getCourse()

end


function love.load()
	love.window.setMode(1000, 800)
	love.graphics.setPointSize(3)
	calculateTurn()
	--find(startPosition, goalPosition)
end


local function debug(...)
    print(string.format(...))
end

local function drawVehicle(p, i)
    local v = getVehicleRectangle(p, vehicleData, p.t, 0)
    local r, g, b = 0.4, 0.4, 0
    local highlight = i == currentHighlight and 0.4 or 0
    love.graphics.setColor( 0, g + highlight, 0 )
    love.graphics.line(v[1].x, v[1].y, v[2].x, v[2].y)
    love.graphics.setColor( r + highlight, g + highlight, 0 )
    love.graphics.line(v[2].x, v[2].y, v[3].x, v[3].y)
    love.graphics.setColor( r + g, 0, 0 )
    love.graphics.line(v[3].x, v[3].y, v[4].x, v[4].y)
    love.graphics.setColor( 0, r + highlight, g + highlight )
    love.graphics.line(v[4].x, v[4].y, v[1].x, v[1].y)
    v = getVehicleRectangle(p, trailerData, p.tTrailer, -trailerData.dFront)
    love.graphics.setColor( 0, 0.3 + highlight, 0 )
    love.graphics.line(v[1].x, v[1].y, v[2].x, v[2].y)
    love.graphics.setColor( 0, 0, 0.6 + highlight )
    love.graphics.line(v[2].x, v[2].y, v[3].x, v[3].y)
    love.graphics.setColor( 0.3 + highlight, 0, 0 )
    love.graphics.line(v[3].x, v[3].y, v[4].x, v[4].y)
    love.graphics.setColor( 0, 0, 0.6 + highlight )
    love.graphics.line(v[4].x, v[4].y, v[1].x, v[1].y)
end

---@param node State3D
local function drawNode(node)
    love.graphics.push()
    love.graphics.translate(node.x, node.y)
    love.graphics.rotate(node.t)
    local left, right = -1.0, 1.0
    local triangle = { 0, left, 0, right, 4, 0}
    love.graphics.polygon( 'line', triangle )
    love.graphics.pop()
end

---@param path State3D[]
local function drawPath(path, pointSize, r, g, b)
    if path then
        love.graphics.setPointSize(pointSize)
        for i = 2, #path do
            love.graphics.setColor(r, g, b)
            love.graphics.line(path[i - 1].x, path[i - 1].y, path[i].x, path[i].y)
        end
    end
end

local function drawCourse(course, lineWidth, pointSize, r, g, b)
	if course then
		love.graphics.setLineWidth(lineWidth)
		for i = 1, #course do
			local cp, pp = course[i], course[i - 1]
			if r then
				love.graphics.setColor(r, g, b, 0.2)
				if pp then love.graphics.line(pp.z, pp.x, cp.z, cp.x) end
			elseif cp.rev then
				love.graphics.setColor(0, 0.3, 1, 1)
				love.graphics.print(string.format('%d', i), cp.z, cp.x, 0, 0.04, -0.04, 15, 15)
				love.graphics.setColor(0, 0, 1, 0.5)
				if pp then love.graphics.line(pp.z + 0.1, pp.x + 0.1, cp.z + 0.1, cp.x + 0.1) end
			else
				love.graphics.setColor(0.2, 1, 0.2, 1)
				love.graphics.print(string.format('%d', i), cp.z, cp.x, 0, 0.04, -0.04, -5, -5)
				love.graphics.setColor(0.2, 1, 0.2, 0.5)
				if pp then love.graphics.line(pp.z, pp.x, cp.z, cp.x) end
			end
			love.graphics.setPointSize(pointSize)
			if cp.turnStart then
				love.graphics.setColor(0, 1, 0)
				love.graphics.points(cp.z, cp.x)
			end
			if cp.turnEnd then
				love.graphics.setColor(1, 0, 0)
				love.graphics.points(cp.z, cp.x)
			end
		end
	end
end

local function showStatus()
    love.graphics.setColor(1,1,1)

    if path then
        if constraints:isValidNode(path[math.min(#path, currentHighlight)]) then
            love.graphics.print('VALID', 10, 20)
        else
            love.graphics.print('NOT VALID', 10, 20)
        end
    end

	love.graphics.print(string.format('back: %.1f front %.1f steering length: %.1f radius %.1f width %.1f edge %.1f',
		backMarkerDistance, frontMarkerDistance, steeringLength, turningRadius, workWidth, distanceToFieldEdge), 10, 30)

end

function love.draw()
	if startPosition ~= lastStartPosition or goalPosition ~= lastGoalPosition then
		find(startPosition, goalPosition)
	end

    love.graphics.push()
    love.graphics.scale(scale, -scale)
    love.graphics.translate(xOffset, -yOffset)

    love.graphics.setColor( 0.2, 0.2, 0.2 )
    love.graphics.setLineWidth(0.2)
    love.graphics.line(-1000, 0, 1000, 0)
    love.graphics.line(0, -1000, 0, 1000)

    love.graphics.setColor( 0, 1, 0 )
    love.graphics.setPointSize(3)
    love.graphics.points(line)

    love.graphics.setColor(0.0, 0.8, 0.0)
    drawNode(startPosition)
    love.graphics.setColor(0.8, 0.0, 0.0)
    drawNode(goalPosition)
    love.graphics.setColor(0, 0.8, 0)

    love.graphics.setPointSize(5)

    drawPath(dubinsPath, 3, 0.8, 0.8, 0)
    drawPath(rsPath, 2, 0, 0.3, 0.8)

    if path then
        love.graphics.setPointSize(0.5 * scale)
        for i = 2, #path do
            local p = path[i]
            if p.gear == Gear.Backward then
                love.graphics.setColor(0, 0.4, 1)
            elseif p.gear == Gear.Forward then
                love.graphics.setColor( 1, 1, 1 )
            else
                love.graphics.setColor(0.4, 0, 0)
            end
            love.graphics.setLineWidth(0.1)
            love.graphics.line(p.x, p.y, path[i-1].x, path[i - 1].y)
            --love.graphics.points(p.x, p.y)
            drawVehicle(p, i)
        end
    end

	love.graphics.setColor( 0.3, 0.3, 0.3 )
	love.graphics.line(10, courseLength + distanceToFieldEdge, 30, courseLength + distanceToFieldEdge)

	for _, c in pairs(courses) do
		drawCourse(c.waypoints, workWidth, 8, 0.5, 0.5, 0.5)
	end
	for _, c in pairs(turnCourses) do
		drawCourse(c.waypoints, 0.1, 2)
	end
	for _, c in pairs(turnContexts) do
		c:drawDebug()
	end

    love.graphics.pop()
    showStatus()
end




local function love2real( x, y )
    return ( x / scale ) - xOffset,  - ( y / scale ) + yOffset
end

function love.keypressed(key, scancode, isrepeat)
    local headingStepDeg = 15
    if key == 'left' then
        if love.keyboard.isDown('lshift') then
            startPosition:addHeading(math.rad(headingStepDeg))
        else
            goalPosition:addHeading(math.rad(headingStepDeg))
        end
    elseif key == 'right' then
        if love.keyboard.isDown('lshift') then
            startPosition:addHeading(-math.rad(headingStepDeg))
        else
            goalPosition:addHeading(-math.rad(headingStepDeg))
        end
    elseif key == '=' then
        scale = scale * 1.2
    elseif key == '-' then
        scale = scale / 1.2
    elseif key == 'p' then
        currentPathfinderIndex = (currentPathfinderIndex + 1) > #pathfinders and 1 or currentPathfinderIndex + 1
    end
    io.stdout:flush()
end

function love.textinput(key)
	if key == 'b' then
		backMarkerDistance = backMarkerDistance - 0.5
		calculateTurn()
	elseif key == 'B' then
		backMarkerDistance = backMarkerDistance + 0.5
		calculateTurn()
	elseif key == 'f' then
		frontMarkerDistance = frontMarkerDistance - 0.5
		calculateTurn()
	elseif key == 'F' then
		frontMarkerDistance = frontMarkerDistance + 0.5
		calculateTurn()
	elseif key == 's' then
		steeringLength = math.max(0, steeringLength - 0.2)
		calculateTurn()
	elseif key == 'S' then
		steeringLength = steeringLength + 0.2
		calculateTurn()
	elseif key == 'r' then
		turningRadius = math.max(3, turningRadius - 0.2)
		calculateTurn()
	elseif key == 'R' then
		turningRadius = turningRadius + 0.2
		calculateTurn()
	elseif key == 'w' then
		workWidth = math.max(1, workWidth - 0.2)
		calculateTurn()
	elseif key == 'W' then
		workWidth = workWidth + 0.2
		calculateTurn()
	elseif key == 'e' then
		distanceToFieldEdge = math.max(1, distanceToFieldEdge - 0.5)
		calculateTurn()
	elseif key == 'E' then
		distanceToFieldEdge = distanceToFieldEdge + 0.5
		calculateTurn()
	end
end

function love.mousepressed(x, y, button, istouch)
    -- left shift + left click: find path forward only,
    -- left ctrl + left click: find path with reversing allowed
    if button == 1 then
        if love.keyboard.isDown('lshift') or love.keyboard.isDown('lctrl') then
            goalPosition.x, goalPosition.y = love2real( x, y )
            --print(love.profiler.report(profilerReportLength))
            done, path, goalNodeInvalid = find(startPosition, goalPosition, love.keyboard.isDown('lctrl'))

            if path then
                debug('Path found with %d nodes', #path)
            elseif done then
                debug('No path found')
                if goalNodeInvalid then
                    debug('Goal node invalid')
                end
            end
        elseif love.keyboard.isDown('lalt') then
            startPosition.x, startPosition.y = love2real( x, y )
			calculateTurn()
        else
            dragging = true
        end
        io.stdout:flush()
    end
end

function love.mousereleased(x, y, button, istouch)
    if button == 1 then
        dragging = false
    end
end

function love.mousemoved( x, y, dx, dy )
    if dragging then
        xOffset = xOffset + dx / scale
        yOffset = yOffset + dy / scale
    end
end

function love.wheelmoved( dx, dy )
    xOffset = xOffset + dy / scale / 2
    yOffset = yOffset - dy / scale / 2
    scale = scale + scale * dy * 0.05
end
