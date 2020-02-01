--[[

LOVE app to test the Courseplay pathfinding

]]--

dofile( 'include.lua' )

local obstacle = {
    x1 = 13,
    y1 = 5,
    x2 = 15,
    y2 = 15
}

---@param node State3D
---@param userdata table
local function isValidNode(node, userdata)
    local isInObstacle = node.x > obstacle.x1 and node.x < obstacle.x2 and node.y > obstacle.y1 and node.y < obstacle.y2
    return not isInObstacle
end

local turnRadius = 5
local goalHeading = 0 --math.pi
local startHeading = 0 --math.pi

local start = State3D(0, 0, startHeading, 0)
local goal = State3D(10, 0, goalHeading, 0)
local dubinsPath = {}
local rsPath = {}
local rsSolver = ReedsSheppSolver()
local dubinsSolver = DubinsSolver()
local pathFinder = HybridAStar(200)
local done, path

local function printPath(path)
    for i, p in ipairs(path) do
        print(i, tostring(p))
    end
end

local function find(start, goal, allowReverse)
    local vehicleData ={name = 'name', turnRadius = turnRadius, dFront = 3, dRear = 3, dLeft = 1.5, dRight = 1.5}
    done, path = pathFinder:start(start, goal, vehicleData.turnRadius, vehicleData, allowReverse,nil, isValidNode)
    local dubinsSolution = dubinsSolver:solve(start, goal, turnRadius)
    dubinsPath = dubinsSolution:getWaypoints(start, turnRadius)
    local rsActionSet = rsSolver:solve(start, goal, turnRadius)
    rsPath = rsActionSet:getWaypoints(start, vehicleData.turnRadius)
    if done and path then
        printPath(path)
    end
    io.stdout:flush()
    return done, path
end

local scale, width, height = 10, 1000, 800
local xOffset, yOffset = width / scale / 2, height / scale / 2

local function debug(...)
    print(string.format(...))
end

local function drawNode(node)
    love.graphics.push()
    love.graphics.translate(node.x, node.y)
    love.graphics.rotate(node.t)
    local left, right = -1.0, 1.0
    local triangle = { 0, left, 0, right, 4, 0}
    love.graphics.polygon( 'fill', triangle )
    love.graphics.pop()
end

local function drawObstacle(obstacle)
    love.graphics.setColor( 90, 90, 90 )
    love.graphics.rectangle('fill', obstacle.x1, obstacle.y1, obstacle.x2 - obstacle.x1, obstacle.y2 - obstacle.y1)
end

function love.load()
    love.window.setMode(1000, 800)
    love.graphics.setPointSize(3)
    find(start, goal)

end

function love.draw()
    love.graphics.scale(scale, -scale)
    love.graphics.translate(xOffset, -yOffset)


    love.graphics.setColor( 50, 50, 50 )
    love.graphics.line(-1000, 0, 1000, 0)
    love.graphics.line(0, -1000, 0, 1000)

    local nodes
    if pathFinder then
        if pathFinder.nodes then
            nodes = pathFinder.nodes
        elseif pathFinder.hybridAStarPathFinder and pathFinder.hybridAStarPathFinder.nodes then
            nodes = pathFinder.hybridAStarPathFinder.nodes
        end
        if nodes then
            for _, row in pairs(nodes.nodes) do
                for _, column in pairs(row) do
                    for _, cell in pairs(column) do
                        if cell.pred == cell then
                            love.graphics.setPointSize(5)
                            love.graphics.setColor( 0, 100, 100 )
                        else
                            local range = nodes.highestCost - nodes.lowestCost
                            local color = (cell.cost - nodes.lowestCost) * 250 / range
                            love.graphics.setPointSize(1)
                            if cell:isClosed() then
                                love.graphics.setColor(100 + color, 250 - color, 0 )
                            else
                                love.graphics.setColor( 0, 80, cell.cost *3 )
                            end
                        end
                        if cell.pred then
                            love.graphics.setLineWidth(0.1)
                            love.graphics.line(cell.x, cell.y, cell.pred.x, cell.pred.y)
                        else
                            love.graphics.setPointSize(3)
                            love.graphics.points(cell.x, cell.y)
                        end
                        love.graphics.print(string.format('%d', cell.h), cell.x, cell.y, 0, 0.04, -0.04)
            end
        end
            end
        end
    end

    love.graphics.setColor(200, 200, 0)
    drawNode(goal)
    drawNode(start)
    drawObstacle(obstacle)

    love.graphics.setPointSize(5)

    if dubinsPath then
        for i, p in ipairs(dubinsPath) do
            love.graphics.setColor(200, 200, 0)
            love.graphics.points(p.x, p.y)
        end
    end

    if rsPath then
        for i, p in ipairs(rsPath) do
            love.graphics.setColor(100, 0, 200)
            love.graphics.points(p.x, p.y)
        end
    end

    if path then
        for i = 2, #path do
            local p = path[i]
            if p.gear == HybridAStar.Gear.Backward then
                love.graphics.setColor(0, 100, 255)
            elseif p.gear == HybridAStar.Gear.Forward then
                love.graphics.setColor( 255, 255, 255 )
            else
                love.graphics.setColor(100, 0, 0)
            end
            love.graphics.setLineWidth(0.3)
            love.graphics.line(p.x, p.y, path[i-1].x, path[i - 1].y)
        end
    end

    if pathFinder:isActive() then
        done, path = pathFinder:resume()
        if done and path then
            printPath(path)
            io.stdout:flush()
        end
    end
end


local function love2real( x, y )
    return ( x / scale ) - xOffset,  - ( y / scale ) + yOffset
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        goal.x, goal.y = love2real( x, y )

        done, path = find(start, goal, love.keyboard.isDown('lctrl'))

        if path then
            debug('Path found with %d nodes', #path)
        elseif done then
            debug('No path found')
        end
    end
    io.stdout:flush()
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
    end
    xOffset, yOffset = width / scale / 2, height / scale / 2
    io.stdout:flush()
end
