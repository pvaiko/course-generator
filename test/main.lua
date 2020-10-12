--[[

LOVE app to test the Courseplay pathfinding

]]--

dofile( 'include.lua' )

local obstacles = {


    {
        x1 = 13,
        y1 = 100,
        x2 = 400,
        y2 = 120
    },

    {
        x1 = -10,
        y1 = 5,
        x2 = -60,
        y2 = 10
    },


    {
        x1 = 110,
        y1 = 5,
        x2 = 115,
        y2 = 15
    },

    {
        x1 = 100,
        y1 = 15,
        x2 = 115,
        y2 = 20
    }
}
---@param node State3D
---@param userdata table
local function isValidNode(node, userdata)
    for _, obstacle in ipairs(obstacles) do
        local isInObstacle = node.x >= obstacle.x1 and node.x <= obstacle.x2 and node.y >= obstacle.y1 and node.y <= obstacle.y2
        if isInObstacle then return false end
    end
    return true
end

local dragging = false
local startTime
local profilerReportLength = 40
local turnRadius = 5

local scale, width, height = 2, 500, 400
local origin = {x = -width / 8, y = -height / 4}
local xOffset, yOffset = width / scale / 4, height / scale

local goalHeading = 0* math.pi / 4
local startHeading = 0*math.pi / 4

local start = State3D(0, 0, startHeading, 0)
--local goal = State3D(120, 8, goalHeading, 0)
local goal = State3D(300, 150, goalHeading, 0)
local dubinsPath = {}
local grid = Grid(1, width / 2,height / 2, origin)
local heuristic = NonholonomicRelaxed(grid)
local rsPath = {}
local rsSolver = ReedsSheppSolver()
local dubinsSolver = DubinsSolver()
local pathfinders = {
    HybridAStarWithAStarInTheMiddle(20, 200, 100000),
    HybridAStarWithHeuristic(20, 200, 100000),
    HybridAStar(200, 100000)
}
local pathfinderTexts = {
    'HybridAStarWithAStarInTheMiddle',
    'HybridAStarWithHeuristic',
    'HybridAStar'
}
local currentPathfinderIndex = 1
local done, path

local function printPath(path)
    for i, p in ipairs(path) do
        print(i, tostring(p))
    end
end

local line = {}

local function plotLine(x0, y0, x1, y1)
    x0, y0, x1, y1 = math.floor(x0), math.floor(y0), math.floor(x1), math.floor(y1)
    local dx, sx = math.abs(x1 - x0), x0 < x1 and 1 or -1
    local dy, sy = -math.abs(y1 - y0), y0 < y1 and 1 or -1
    local err, e2 = dx + dy

    while true do
        table.insert(line, {x0, y0})
        e2 = 2 * err
        if e2 >= dy then
            if x0 == x1 then break end
            err = err + dy
            x0 = x0 + sx
        end
        if e2 <= dx then
            if y0 == y1 then break end
            err = err + dx
            y0 = y0 + sy
        end
    end
end

local function plotThickLine(p0, p1, w)
    line = {}

    w = math.max(2, math.floor(w + 0.5))
    local halfWidth = math.floor(w / 2 + 0.5)
    local dx, dy = p1.x - p0.x, p1.y - p0.y
    local s = Vector(p0.x, p0.y)
    local v = Vector(dx, dy):rotate(math.rad(-90))
    plotLine(p0.x, p0.y, p1.x, p1.y)
    for w1 = 1, halfWidth do
        v:setLength(w1)
        local s1 = s + v
        plotLine(s1.x, s1.y, s1.x + dx, s1.y + dy)
    end
    v = Vector(dx, dy):rotate(math.rad(90))
    for w1 = 1, halfWidth do
        v:setLength(w1)
        local s1 = s + v
        plotLine(s1.x, s1.y, s1.x + dx, s1.y + dy)
    end
end


local function plotThickLineBad(x0, y0, x1, y1, wd)

    x0, y0, x1, y1 = math.floor(x0 + 0.5), math.floor(y0 + 0.5), math.floor(x1 + 0.5), math.floor(y1 + 0.5)

    local dx, sx = math.abs(x1 - x0), x0 < x1 and 1 or -1
    local dy, sy = math.abs(y1 - y0), y0 < y1 and 1 or -1
    local err = dx - dy
    local e2, x2, y2

    local ed = (dx + dy) == 0 and 1 or math.sqrt(dx * dx + dy * dy)
    local wd2 = wd / 2
    wd = (wd + 1) / 2
    line = {}

    while true do
        table.insert(line, {x0, y0})
        e2 = err
        x2 = x0
        if (2 * e2 >= -dx) then
            e2 = e2 + dy
            y2 = y0 -- sy * wd2
            while e2 < ed * wd and (y1 ~= y2 or dx > dy) do
                y2 = y2 + sy
                print(x0, y2, e2, ed, dx, dy)
                table.insert(line, {x0, y2})
                e2 = e2 + dx
            end
            if (x0 == x1) then break end
            e2 = err
            err = err - dy
            print('x0', x0)
            x0 = x0 + sx
        end
        if (2 * e2 <= dy) then
            e2 = dx - e2
            while e2 < ed * wd and (x1 ~= x2 or dx < dy) do
                x2 = x2 + sx
                print('@@ ', x2, y0)
                table.insert(line, {x2, y0})
                e2 = e2 + dy
            end

            if (y0 == y1) then break end
            err = err + dx
            print('y0', y0)
            y0 = y0 + sy
        end
    end
end

local function find(start, goal, allowReverse)
    love.profiler.start()
    startTime = love.timer.getTime()
    --heuristic:update(goal, isValidNode)

    local vehicleData ={name = 'name', turnRadius = turnRadius, dFront = 3, dRear = 3, dLeft = 1.5, dRight = 1.5}
    done, path = pathfinders[currentPathfinderIndex]:start(start, goal, vehicleData.turnRadius, vehicleData, allowReverse, nil, isValidNode, isValidNode)
    --plotThickLine(start, goal, 12)
    local dubinsSolution = dubinsSolver:solve(start, goal, turnRadius)
    dubinsPath = dubinsSolution:getWaypoints(start, turnRadius)
    local rsActionSet = rsSolver:solve(start, goal, turnRadius)
    rsPath = rsActionSet:getWaypoints(start, vehicleData.turnRadius)

    if done and path then
        --printPath(path)
        print(love.profiler.report(profilerReportLength))
        love.profiler.reset()

    end
    love.profiler.stop()
    io.stdout:flush()
    return done, path
end

local function debug(...)
    print(string.format(...))
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

local function drawHeuristicGrid(heuristic)
    local range = (heuristic.maxValue - heuristic.minValue)
    for c = 1, #heuristic.heuristic do
        for r = 1, #heuristic.heuristic[c] do
                local pos = heuristic.grid:cellPositionToPointPosition(c, r)
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print(string.format('%d', heuristic.heuristic[c][r]), pos.x, pos.y, 0, 0.04, -0.04)

              --  love.graphics.setColor((heuristic.heuristic[c][r] - heuristic.minValue) / range, 0, 0)
                --love.graphics.points(pos.x, pos.y)
        end
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

    drawHeuristicGrid(heuristic)

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
        end
    end
    drawPath(pathfinders[currentPathfinderIndex].middlePath, 6, 0.7, 0.7, 0.0)

    if pathfinders[currentPathfinderIndex]:isActive() then
        love.profiler.start()
        done, path = pathfinders[currentPathfinderIndex]:resume()
        love.profiler.stop()
        if done and path then
            --printPath(path)
            print(string.format('Done in %.2f seconds', love.timer.getTime() - startTime))
            print(love.profiler.report(profilerReportLength))
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
            print(love.profiler.report(profilerReportLength))
            done, path = find(start, goal, love.keyboard.isDown('lctrl'))

            if path then
                debug('Path found with %d nodes', #path)
            elseif done then
                debug('No path found')
            end
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
