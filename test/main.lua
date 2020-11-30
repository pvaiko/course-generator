--[[

LOVE app to test the Courseplay pathfinding

]]--

dofile( 'include.lua' )

local goalHeading = 0 * math.pi / 4
local startHeading = 0 * math.pi / 4

local start = State3D(0, 0, startHeading, 0)
--local goal = State3D(120, 8, goalHeading, 0)
local goal = State3D(0, 150, goalHeading, 0)

local turnRadius = 5
local vehicleData ={name = 'name', turnRadius = turnRadius, dFront = 4, dRear = 2, dLeft = 1.5, dRight = 1.5}

local obstacles = {
    { x1 = 13, y1 = 100, x2 = 400, y2 = 120 },
    { x1 = -10, y1 = 5, x2 = -60, y2 = 10 },
}
local fruit = {
    { x1 = 25, y1 = 5, x2 = 110, y2 = 25 },
    { x1 = 80, y1 = 25, x2 = 325, y2 = 40 }
}

---@param node State3D
---@param table {dFront, dRear, dLeft, dRight}
local function getVehicleRectangle(node, vehicleData)
    local fl = node + Vector(vehicleData.dFront, -vehicleData.dLeft):rotate(node.t)
    local fr = node + Vector(vehicleData.dFront, vehicleData.dRight):rotate(node.t)
    local rl = node + Vector(-vehicleData.dRear, -vehicleData.dLeft):rotate(node.t)
    local rr = node + Vector(-vehicleData.dRear, vehicleData.dRight):rotate(node.t)
    -- make sure it works with the Giants coordinate system functions in the x-z plane
    fl.z = fl.y
    fr.z = fr.y
    rl.z = rl.y
    rr.z = rr.y
    return {fl, fr, rr, rl}
end


---@class TestPathfinderConstraints : PathfinderConstraintInterface
local TestPathfinderConstraints = CpObject(PathfinderConstraintInterface)

function TestPathfinderConstraints:init()
    self:resetConstraints()
end

---@param node State3D
---@param userdata table
function TestPathfinderConstraints:isValidNode(node)
    for _, obstacle in ipairs(obstacles) do
        local isInObstacle = node.x >= obstacle.x1 and node.x <= obstacle.x2 and node.y >= obstacle.y1 and node.y <= obstacle.y2
        if isInObstacle then
            return false
        end
        if PathfinderUtil.doRectanglesOverlap(
                {{x = obstacle.x1, z = obstacle.y1},
                 {x = obstacle.x2, z = obstacle.y1},
                 {x = obstacle.x2, z = obstacle.y2},
                 {x = obstacle.x1, z = obstacle.y2}},
                getVehicleRectangle(node, vehicleData)) then
            return false
        end
    end
    return true
end

function TestPathfinderConstraints:getNodePenalty(node)
    for _, obstacle in ipairs(fruit) do
        local isInObstacle = node.x >= obstacle.x1 and node.x <= obstacle.x2 and node.y >= obstacle.y1 and node.y <= obstacle.y2
        if isInObstacle then
            return 200
        end
    end
    return 0
end

function TestPathfinderConstraints:isValidAnalyticSolutionNode(node)
    local fruitValue = self:getNodePenalty(node)
    if fruitValue > self.fruitLimit then return false end
    return self:isValidNode(node)
end

function TestPathfinderConstraints:relaxConstraints()
    print('Relaxing fruit limit to math.huge')
    self.fruitLimit = math.huge
end

function TestPathfinderConstraints:resetConstraints()
    print('Resetting fruit limit to 100')
    self.fruitLimit = 100
end

local dragging = false
local startTime
local profilerReportLength = 40

local constraints = TestPathfinderConstraints()

local scale, width, height = 3, 500, 400
local origin = {x = -width / 8, y = -height / 4}
local xOffset, yOffset = width / scale / 4, height / scale

local dubinsPath = {}
local rsPath = {}
local rsSolver = ReedsSheppSolver()
local dubinsSolver = DubinsSolver()
local pathfinders = {
    HybridAStarWithAStarInTheMiddle(20, 200, 10000),
    HybridAStar(200, 20000)
}
local pathfinderTexts = {
    'HybridAStarWithAStarInTheMiddle',
    'HybridAStarWithHeuristic',
    'HybridAStar'
}
local currentPathfinderIndex = 1
local done, path, goalNodeInvalid

local line = {}

local function find(start, goal, allowReverse)
    love.profiler.start()
    startTime = love.timer.getTime()
    --heuristic:update(goal, isValidNode)

    done, path, goalNodeInvalid = pathfinders[currentPathfinderIndex]:start(start, goal, vehicleData.turnRadius, allowReverse,
            constraints)
    --plotThickLine(start, goal, 12)
    local dubinsSolution = dubinsSolver:solve(start, goal, turnRadius)
    dubinsPath = dubinsSolution:getWaypoints(start, turnRadius)
    local rsActionSet = rsSolver:solve(start, goal, turnRadius)
    rsPath = rsActionSet:getWaypoints(start, vehicleData.turnRadius)

    if done and path then
        --printPath(path)
        --print(love.profiler.report(profilerReportLength))
        love.profiler.reset()

    end
    love.profiler.stop()
    io.stdout:flush()
    return done, path, goalNodeInvalid
end

local function debug(...)
    print(string.format(...))
end

local function printPath(path)
    for i, p in ipairs(path) do
       -- print(i, tostring(p))
    end
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

local function drawObstacles(obstacles)
    for _, obstacle in ipairs(obstacles) do
        love.graphics.setColor( 0.4, 0.4, 0.4 )
        love.graphics.rectangle('line', obstacle.x1, obstacle.y1, obstacle.x2 - obstacle.x1, obstacle.y2 - obstacle.y1)
    end
end

---@param path State3D[]
local function drawPath(path, pointSize, r, g, b)
    if path then
        love.graphics.setPointSize(pointSize)
        for i, p in ipairs(path) do
            love.graphics.setColor(r, g, b)
            love.graphics.points(p.x, p.y)
        end
    end
end

local function drawNodes(nodes)
    if nodes then
        for _, row in pairs(nodes.nodes) do
            for _, column in pairs(row) do
                for _, cell in pairs(column) do
                    if cell.pred == cell then
                        love.graphics.setPointSize(5)
                        love.graphics.setColor( 0, 0.5, 0.5 )
                    else
                        local range = nodes.highestCost - nodes.lowestCost
                        local color = (cell.cost - nodes.lowestCost) / range
                        love.graphics.setPointSize(1)
                        if cell:isClosed() then
                            love.graphics.setColor(0.5 + color, 1 - color, 0 )
                        else
                            love.graphics.setColor( 0, 0.4, cell.cost * 3 / 255 )
                        end
                    end
                    if cell.pred then
                        love.graphics.setLineWidth(0.1)
                        love.graphics.line(cell.x, cell.y, cell.pred.x, cell.pred.y)
                    else
                        love.graphics.setPointSize(3)
                        love.graphics.points(cell.x, cell.y)
                    end
                    love.graphics.print(string.format('%d', cell.cost), cell.x, cell.y, 0, 0.04, -0.04)
                end
            end
        end
    end
end
function love.load()

    require("mobdebug").start()
    love.profiler = require('profile')

    love.window.setMode(1000, 800)
    love.graphics.setPointSize(3)
    find(start, goal, true)


end

local function showStatus()
    love.graphics.setColor(1,1,1)

    love.graphics.print(pathfinderTexts[currentPathfinderIndex], 10, 10)
end

function love.draw()
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

    if pathfinders[currentPathfinderIndex] then
        if pathfinders[currentPathfinderIndex].nodes then
            drawNodes(pathfinders[currentPathfinderIndex].nodes)
        end
        if pathfinders[currentPathfinderIndex].aStarPathfinder and pathfinders[currentPathfinderIndex].aStarPathfinder.nodes then
            drawNodes(pathfinders[currentPathfinderIndex].aStarPathfinder.nodes)
        end
        if pathfinders[currentPathfinderIndex].hybridAStarPathfinder and pathfinders[currentPathfinderIndex].hybridAStarPathfinder.nodes then
            drawNodes(pathfinders[currentPathfinderIndex].hybridAStarPathfinder.nodes)
        end
    end

    love.graphics.setColor(0.8, 0.8, 0)
    drawNode(goal)
    drawNode(start)
    drawObstacles(obstacles)
    love.graphics.setColor(0, 0.8, 0)
    drawObstacles(fruit)

    love.graphics.setPointSize(5)

    drawPath(dubinsPath, 2, 0.8, 0.8, 0)
    drawPath(rsPath, 2, 0.4, 0, 0.8)

    if pathfinders[currentPathfinderIndex].aStarPath then
        drawPath(pathfinders[currentPathfinderIndex].aStarPath, 10, 1, 0, 1)
    end

    if path then
        love.graphics.setPointSize(0.5 * scale)
        for i = 2, #path do
            local p = path[i]
            if p.gear == HybridAStar.Gear.Backward then
                love.graphics.setColor(0, 0.4, 1)
            elseif p.gear == HybridAStar.Gear.Forward then
                love.graphics.setColor( 1, 1, 1 )
            else
                love.graphics.setColor(0.4, 0, 0)
            end
            love.graphics.setLineWidth(0.1)
            love.graphics.line(p.x, p.y, path[i-1].x, path[i - 1].y)
            --love.graphics.points(p.x, p.y)
            local v = getVehicleRectangle(p, vehicleData)
            love.graphics.setColor( 0, 0.4, 0 )
            love.graphics.line(v[1].x, v[1].y, v[2].x, v[2].y)
            love.graphics.setColor( 0.4, 0.4, 0 )
            love.graphics.line(v[2].x, v[2].y, v[3].x, v[3].y)
            love.graphics.setColor( 0.4, 0, 0 )
            love.graphics.line(v[3].x, v[3].y, v[4].x, v[4].y)
            love.graphics.setColor( 0, 0.4, 0.4 )
            love.graphics.line(v[4].x, v[4].y, v[1].x, v[1].y)
        end
    end
    drawPath(pathfinders[currentPathfinderIndex].middlePath, 6, 0.7, 0.7, 0.0)

    if pathfinders[currentPathfinderIndex]:isActive() then
        love.profiler.start()
        done, path = pathfinders[currentPathfinderIndex]:resume()
        love.profiler.stop()
        if done and path then
            printPath(path)
            print(string.format('Done in %.2f seconds', love.timer.getTime() - startTime))
            --print(love.profiler.report(profilerReportLength))
            love.profiler.reset()
            io.stdout:flush()
        end
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
            start:addHeading(math.rad(headingStepDeg))
        else
            goal:addHeading(math.rad(headingStepDeg))
        end
    elseif key == 'right' then
        if love.keyboard.isDown('lshift') then
            start:addHeading(-math.rad(headingStepDeg))
        else
            goal:addHeading(-math.rad(headingStepDeg))
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

function love.mousepressed(x, y, button, istouch)
    -- left shift + left click: find path forward only,
    -- left ctrl + left click: find path with reversing allowed
    if button == 1 then
        if love.keyboard.isDown('lshift') or love.keyboard.isDown('lctrl') then
            goal.x, goal.y = love2real( x, y )
            --print(love.profiler.report(profilerReportLength))
            done, path, goalNodeInvalid = find(start, goal, love.keyboard.isDown('lctrl'))

            if path then
                debug('Path found with %d nodes', #path)
            elseif done then
                debug('No path found')
                if goalNodeInvalid then
                    debug('Goal node invalid')
                end
            end
        elseif love.keyboard.isDown('lalt') then
            start.x, start.y = love2real( x, y )
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
